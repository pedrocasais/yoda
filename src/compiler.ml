open Job

(* Cria /tmp/yodac_{submission_id}/ e escreve o código *)
let prepare_workdir job =
  let dir = Printf.sprintf "/tmp/submission_%d" job.submission_id in
  Unix.mkdir dir 0o700;
  let ext = Job.string_of_lang job.lang in
  let src = Printf.sprintf "%s/main.%s" dir ext in
  let oc  = open_out src in
  output_string oc job.source_code;
  close_out oc;
  (dir, src)

(* Corre um comando e devolve (exit_code, output) *)
let run_command cmd =
  let ic = Unix.open_process_in (cmd ^ " 2>&1") in
  let output = In_channel.input_all ic in
  let status = Unix.close_process_in ic in
  match status with
  | Unix.WEXITED code -> (code, output)
  | _                 -> (1, output)

(* Compila se necessário — devolve Ok caminho_binário ou Error mensagem *)
let compile job dir src =
  match job.lang with
  | C ->
      let bin = dir ^ "/main" in
      (match run_command (Printf.sprintf "gcc -o %s %s -lm" bin src) with
       | (0, _)   -> Ok bin
       | (_, err) -> Error err)
  | Cpp ->
      let bin = dir ^ "/main" in
      (match run_command (Printf.sprintf "gcc -o %s %s" bin src) with
       | (0, _)   -> Ok bin
       | (_, err) -> Error err)
  | OCaml ->
      let bin = dir ^ "/main" in
      (match run_command (Printf.sprintf "ocamlfind ocamlopt -package str -linkpkg -o %s %s" bin src) with
       | (0, _)   -> Ok bin
       | (_, err) -> Error err)
  | Java ->
      (match run_command (Printf.sprintf "javac -d %s %s" dir src) with
       | (0, _)   -> Ok dir
       | (_, err) -> Error err)
  | Python | JavaScript ->
      Ok src  (* não precisa de compilar *)