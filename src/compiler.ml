(** Compilação de código submetido pelo utilizador.

    Este módulo é responsável por preparar o ambiente de trabalho,
    ler a configuração de linguagens do ficheiro {i languages.yaml}
    e compilar o código dentro de um container Docker isolado. *)

open Job

(** Directório raiz onde são criados os ambientes de trabalho.
    Pode ser configurado via variável de ambiente [YODAC_WORK_ROOT].
    Por omissão: [/yodac]. *)
let work_root =
  Option.value (Sys.getenv_opt "YODAC_WORK_ROOT") ~default:"/yodac"

(** Caminho para o ficheiro de configuração de linguagens.
    Pode ser configurado via variável de ambiente [YODAC_LANG_CONFIG].
    Por omissão: [languages.yaml]. *)
let lang_config_path =
  Option.value (Sys.getenv_opt "YODAC_LANG_CONFIG") ~default:"languages.yaml"

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
           lang_config_path)
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

(** Cria um directório se não existir e garante permissões de escrita. *)
let ensure_dir path =
  if not (Sys.file_exists path) then Unix.mkdir path 0o777;
  Unix.chmod path 0o777

(** Prepara o directório de trabalho para uma submissão.
    Cria [/yodac/submission_{id}/] e escreve o código fonte no ficheiro.
    @return par [(dir, src)] com o caminho do directório e do ficheiro fonte. *)
let prepare_workdir job =
  ensure_dir work_root;
  let dir = Printf.sprintf "%s/submission_%d" work_root job.submission_id in
  ensure_dir dir;
  let ext = lang_ext job.lang in
  let src = Printf.sprintf "%s/main.%s" dir ext in
  let oc = open_out src in
  output_string oc job.source_code;
  close_out oc;
  (dir, src)

(** Executa um comando e devolve [(exit_code, output)].
    O stderr é redireccionado para stdout. *)
let run_command cmd =
  let ic = Unix.open_process_in (cmd ^ " 2>&1") in
  let output = In_channel.input_all ic in
  let status = Unix.close_process_in ic in
  match status with Unix.WEXITED code -> (code, output) | _ -> (1, output)

(** Executa um comando dentro de um container Docker isolado.
    O directório [dir] é montado em [/work] com permissões de escrita.
    Sem acesso à rede ([--network none]). *)
let run_in_sandbox ~dir ~lang cmd =
  run_command
    (Printf.sprintf
       "docker run --rm --network none -v %s:/work:rw -w /work %s sh -c %S"
       dir (lang_image lang) cmd)

(** Compila o código fonte do job dentro de um container Docker.
    Para linguagens interpretadas devolve [Ok dir] sem compilar.
    @return [Ok path] com o caminho do binário, ou [Error msg] se falhar. *)
let compile job dir _src =
  match lang_compile_cmd job.lang with
  | None -> Ok dir
  | Some cmd -> (
    match run_in_sandbox ~dir ~lang:job.lang cmd with
    | 0, _ -> Ok (dir ^ "/main")
    | _, err -> Error err)