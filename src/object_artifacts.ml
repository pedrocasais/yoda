(** Persistencia de object artifacts no filesystem. *)

let work_root = Option.value (Sys.getenv_opt "YODA_ROOT") ~default:"/yoda"

let rec ensure_dir path =
  match path with
  | "" | "." | "/" -> ()
  | _ ->
      if Sys.file_exists path then ()
      else (
        ensure_dir (Filename.dirname path) ;
        Unix.mkdir path 0o755 )

let sha256_hex content = Digestif.SHA256.(to_hex (digest_string content))

let object_artifact_path ~problem_id sha256 =
  Filename.concat work_root
    (Filename.concat "object_artifacts" (Filename.concat problem_id sha256))

let persist problem_id artifacts =
  let dir =
    Filename.concat work_root (Filename.concat "object_artifacts" problem_id)
  in
  ensure_dir dir ;
  List.map
    (fun (artifact : Openapi.objectArtifact) ->
      let sha256 = sha256_hex artifact.content in
      let path = object_artifact_path ~problem_id sha256 in
      let oc = open_out_bin path in
      Fun.protect
        ~finally:(fun () -> close_out_noerr oc)
        (fun () -> output_string oc artifact.content) ;
      `Assoc
        [("filename", `String artifact.filename); ("sha256", `String sha256)] )
    artifacts
  |> fun stored -> Yojson.Safe.to_string (`List stored)
