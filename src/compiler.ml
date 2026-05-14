open Job

let work_root =
  Option.value (Sys.getenv_opt "YODAC_WORK_ROOT") ~default:"/tmp/yodac"

let lang_config_path =
  Option.value (Sys.getenv_opt "YODAC_LANG_CONFIG") ~default:"languages.yaml"

(* Cache da configuração para não ler o ficheiro a cada job *)
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

let lang_ext lang =
  match Yaml.Util.to_string (get_lang_field lang "ext") with
  | Ok ext -> ext
  | Error (`Msg msg) -> failwith msg

let lang_image lang =
  match Yaml.Util.to_string (get_lang_field lang "image") with
  | Ok image -> image
  | Error (`Msg msg) -> failwith msg

let lang_compile_cmd lang =
  match get_lang_field lang "compile" with
  | `Null -> None
  | `String s -> Some s
  | _ -> failwith "campo 'compile' deve ser string ou null"

let lang_run_cmd lang =
  match Yaml.Util.to_string (get_lang_field lang "run") with
  | Ok cmd -> cmd
  | Error (`Msg msg) -> failwith msg

let ensure_dir path =
  if not (Sys.file_exists path) then Unix.mkdir path 0o777 ;
  Unix.chmod path 0o777

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

let run_command cmd =
  let ic = Unix.open_process_in (cmd ^ " 2>&1") in
  let output = In_channel.input_all ic in
  let status = Unix.close_process_in ic in
  match status with Unix.WEXITED code -> (code, output) | _ -> (1, output)

let run_in_sandbox ~dir ~lang cmd =
  run_command
    (Printf.sprintf
       "docker run --rm --network none -v %s:/work:rw -w /work %s sh -c %S"
       dir (lang_image lang) cmd )

let compile job dir _src =
  match lang_compile_cmd job.lang with
  | None -> Ok dir
  | Some cmd -> (
    match run_in_sandbox ~dir ~lang:job.lang cmd with
    | 0, _ -> Ok (dir ^ "/main")
    | _, err -> Error err )