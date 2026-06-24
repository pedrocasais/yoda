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

(** Caminho para o ficheiro de configuração de linguagens.
    Pode ser configurado via variável de ambiente [YODAC_LANG_CONFIG].
    Por omissão: [languagesv2.yaml]. *)
let lang_config_path =
  Option.value
    (Sys.getenv_opt "YODAC_LANG_CONFIG")
    ~default:"languagesv2.yaml"

(** Cache da configuração de linguagens.
    O ficheiro é lido apenas uma vez no arranque do YodaC. *)
let lang_config : (string * Yaml.value) list Lazy.t =
  lazy
    (let ic = open_in lang_config_path in
     let content =
       Fun.protect
         ~finally:(fun () -> close_in_noerr ic)
         (fun () -> really_input_string ic (in_channel_length ic))
     in
     match Yaml.of_string content with
     | Ok (`O l) -> l
     | Ok _ -> failwith "languages.yaml: formato inválido"
     | Error (`Msg msg) -> failwith msg )

(** Devolve o valor de um campo de configuração para uma linguagem.
    @raise Failure se a linguagem ou o campo não existirem. *)
let get_lang_field lang field =
  let open Yaml.Util in
  match List.assoc_opt lang (Lazy.force lang_config) with
  | None ->
      failwith
        (Printf.sprintf "Linguagem '%s' não configurada em %s" lang
           lang_config_path )
  | Some cfg -> (
    match find field cfg with
    | Ok (Some value) -> value
    | Ok None ->
        failwith
          (Printf.sprintf "Campo '%s' em '%s' não encontrado" field lang)
    | Error (`Msg msg) -> failwith msg )

(** Devolve a extensão do ficheiro fonte para a linguagem dada.
    Por exemplo, ["c"] para C ou ["py"] para Python. *)
let lang_ext lang =
  match Yaml.Util.to_string (get_lang_field lang "ext") with
  | Ok ext -> ext
  | Error (`Msg msg) -> failwith msg

(** Devolve a imagem Docker a usar para compilar e executar a linguagem dada. *)
let lang_image lang =
  match Yaml.Util.to_string (get_lang_field lang "image") with
  | Ok image -> image
  | Error (`Msg msg) -> failwith msg

let lang_tag lang =
  match Yaml.Util.to_string (get_lang_field lang "tag") with
  | Ok tag -> tag
  | Error (`Msg msg) -> failwith msg

(** Devolve o comando de compilação para a linguagem dada.
    Devolve [None] para linguagens interpretadas como Python e JavaScript. *)
let lang_compile_cmd lang =
  match get_lang_field lang "compile" with
  | `Null -> None
  | `String s -> Some s
  | _ -> failwith "campo 'compile' deve ser string ou null"

(** Devolve o comando de execução para a linguagem dada. *)
let lang_run_cmd lang =
  match Yaml.Util.to_string (get_lang_field lang "run") with
  | Ok cmd -> cmd
  | Error (`Msg msg) -> failwith msg

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
      ~network_mode:"none"
      ()
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
