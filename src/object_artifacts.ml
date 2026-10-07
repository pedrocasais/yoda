(** Persistencia de object artifacts no filesystem. *)

let work_root = Config.object_artifacts_root

let rec ensure_dir path =
  match path with
  | "" | "." | "/" -> ()
  | _ ->
      if Sys.file_exists path then ()
      else (
        ensure_dir (Filename.dirname path) ;
        Unix.mkdir path 0o755 )

let sha256_hex content = Digestif.SHA256.(to_hex (digest_string content))

let decode_base64_content filename content =
  try Base64.decode_exn content
  with _ ->
    failwith
      (Printf.sprintf "Invalid base64 object artifact content for '%s'"
         filename )

let object_artifact_path ~problem_id sha256 =
  Filename.concat work_root (Filename.concat problem_id sha256)

let persist problem_id artifacts =
  let dir = Filename.concat work_root problem_id in
  ensure_dir dir ;
  List.map
    (fun (artifact : Openapi.objectArtifact) ->
      let decoded_content =
        decode_base64_content artifact.filename artifact.content
      in
      let size = String.length decoded_content in
      let sha256 = sha256_hex decoded_content in
      let path = object_artifact_path ~problem_id sha256 in
      let oc = open_out_bin path in
      Fun.protect
        ~finally:(fun () -> close_out_noerr oc ; Unix.chmod path 0o755)
        (fun () -> output_string oc decoded_content) ;
      Openapi.ObjectArtifact.create ~filename:artifact.filename ~content:""
        ~sha256 ~size () )
    artifacts
  |> fun stored -> Openapi.ObjectArtifacts.to_json stored
