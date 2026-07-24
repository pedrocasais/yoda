(** Compilação de código submetido pelo utilizador utilizando docker-api.

    Este módulo é responsável por preparar o ambiente de trabalho,
    ler a configuração de linguagens do ficheiro {i languagesv2.yaml}
    e compilar o código dentro de um container Docker isolado. *)

open Job
module C = Docker.Container

(** Diretoria raiz onde são criados os ambientes de trabalho.
    Pode ser configurado via variável de ambiente [YODAC_WORK_ROOT].
    Por omissão: [/var/lib/yodac]. *)
let work_root =
  Option.value (Sys.getenv_opt "YODAC_WORK_ROOT") ~default:"/var/lib/yodac"

(** Devolve o valor de um campo de configuração para uma linguagem.
    @raise Failure se a linguagem ou o campo não existirem. *)
let get_lang_entry lang =
  let entry = Hashtbl.find_opt !Config.current_config lang in
  match entry with
  | Some cfg -> cfg
  | None ->
      failwith
        (Printf.sprintf "Linguagem '%s' não configurada (config key: %s)"
           lang Config.config_key )

(** Devolve a extensão do ficheiro fonte para a linguagem dada.
    Por exemplo, ["c"] para C ou ["py"] para Python. *)
let lang_ext lang = (get_lang_entry lang).ext

(** Devolve a imagem Docker a usar para compilar e executar a linguagem dada. *)
let lang_image lang = (get_lang_entry lang).image

let lang_tag lang = (get_lang_entry lang).tag

(** Devolve o comando de compilação para a linguagem dada.
    Devolve [None] para linguagens interpretadas como Python e JavaScript. *)
let lang_compile_cmd lang = (get_lang_entry lang).compile

(** Devolve o comando de execução para a linguagem dada. *)
let lang_run_cmd lang = (get_lang_entry lang).run

(** Cria uma diretoria se não existir e garante permissões de escrita. *)
let ensure_dir path =
  if not (Sys.file_exists path) then Unix.mkdir path 0o777 ;
  Unix.chmod path 0o777

(** Prepara a diretoria de trabalho da submissão e escreve o código fonte.
    Cria [{work_root}/submission_{id}/main.{ext}].
    @return par [(dir, src)] com a diretoria e o ficheiro fonte. *)
let prepare_workdir job =
  ensure_dir work_root ;
  let dir = Printf.sprintf "%s/submission_%d" work_root job.submission_id in
  ensure_dir dir ;
  let ext = lang_ext job.lang in
  let src = Printf.sprintf "%s/main.%s" dir ext in
  let oc = open_out src in
  output_string oc job.source_code ;
  close_out oc ;
  (dir, src)

(** Lê o output de um stream Docker com limite de tempo.
    Devolve lista vazia se o timeout for atingido.
    @param timeout limite em segundos *)
let read_all_timeout ~timeout st =
  let result = ref None in
  let _t =
    Thread.create
      (fun () ->
        let s = try Docker.Stream.read_all st with _ -> [] in
        result := Some s )
      ()
  in
  let deadline = Unix.gettimeofday () +. timeout in
  let rec poll () =
    match !result with
    | Some s -> s
    | None ->
        if Unix.gettimeofday () > deadline then []
        else (Thread.delay 0.05 ; poll ())
  in
  poll ()

(** Executa um comando de compilação num container Docker isolado.
    Monta [dir] em [/work] com escrita permitida.
    Garante que o container é removido mesmo em caso de erro. *)
let run_in_sandbox ~dir ~lang cmd =
  let image = lang_image lang in
  let tag = lang_tag lang in
  let imagef = Printf.sprintf "%s:%s" image tag in
  let h =
    Docker.Container.host
      ~binds:[Docker.Container.Mount (dir, "/work")]
      ~network_mode:"none" ()
  in
  Common.install_image image ~tag ;
  let c = C.create imagef ["bash"; "-c"; cmd] ~host:h ~workingdir:"/work" in
  let st = C.attach ~stdout:true ~stderr:true c `Stream in
  try
    C.start c ;
    let s = read_all_timeout ~timeout:5.0 st in
    let code = C.wait c in
    C.rm c ;
    let identify (ty, s) =
      match ty with
      | Docker.Stream.Stdout -> "out> " ^ s
      | Docker.Stream.Stderr -> "err> " ^ s
    in
    let output = String.concat "\n" (List.map identify s) in
    (code, output)
  with exn ->
    (try C.stop c with _ -> ()) ;
    (try C.rm c with _ -> ()) ;
    raise exn

(** Compila o código fonte do job dentro de um container Docker.
    Para linguagens interpretadas devolve [Ok dir] sem compilar.
    @return [Ok path] com o caminho do binário, ou [Error msg] se falhar. *)

let compile job dir _src =
  match lang_compile_cmd job.lang with
  | None -> Ok dir
  | Some cmd -> (
    match run_in_sandbox ~dir ~lang:job.lang cmd with
    | 0, _ -> Ok (dir ^ "/main")
    | _, err -> Error err )
