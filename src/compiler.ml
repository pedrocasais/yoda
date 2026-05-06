open Job

let sandbox_image =
  Option.value (Sys.getenv_opt "YODAC_SANDBOX_IMAGE") ~default:"yodac-sandbox"

let work_root =
  Option.value (Sys.getenv_opt "YODAC_WORK_ROOT") ~default:"/tmp/yodac"

let lang_config_path =
  Option.value (Sys.getenv_opt "YODAC_LANG_CONFIG") ~default:"languages.json"

(* Cache da configuração para não ler o ficheiro a cada job *)
let lang_config : (string * Yojson.Basic.t) list Lazy.t = lazy (
  let j = Yojson.Basic.from_file lang_config_path in
  match j with
  | `Assoc l -> l
  | _ -> failwith "languages.json: formato inválido"
)

let get_lang_field lang field =
  let open Yojson.Basic.Util in
  let key = Job.string_of_lang lang in
  match List.assoc_opt key (Lazy.force lang_config) with
  | None -> failwith (Printf.sprintf "Linguagem '%s' não configurada em %s" key lang_config_path)
  | Some cfg -> cfg |> member field

let lang_ext lang =
  Yojson.Basic.Util.to_string (get_lang_field lang "ext")

let lang_compile_cmd lang =
  match get_lang_field lang "compile" with
  | `Null -> None
  | `String s -> Some s
  | _ -> failwith "campo 'compile' deve ser string ou null"

let lang_run_cmd lang =
  Yojson.Basic.Util.to_string (get_lang_field lang "run")

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

let run_in_sandbox ~dir cmd =
  run_command
    (Printf.sprintf
       "docker run --rm --network none --entrypoint /bin/sh -v %s:/work:rw -w /work %s -lc %S"
       dir sandbox_image cmd)

let compile job dir _src =
  match lang_compile_cmd job.lang with
  | None -> Ok dir  (* interpretado, não precisa compilar *)
  | Some cmd ->
    match run_in_sandbox ~dir cmd with
    | 0, _ -> Ok (dir ^ "/main")
    | _, err -> Error err