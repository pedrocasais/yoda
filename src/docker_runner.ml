open Job

let image_of_lang = function
  | C | Cpp -> "yodac-runner-c"
  | OCaml -> "yodac-runner-ocaml"
  | Python -> "yodac-runner-python"
  | Java -> "yodac-runner-java"
  | JavaScript -> "yodac-runner-node"

let run_cmd_of_lang = function
  | C | Cpp -> "/work/main"
  | OCaml -> "/work/main"
  | Python -> "python3 /work/main.py"
  | Java -> "java -cp /work Main"
  | JavaScript -> "node /work/main.js"

(* Corre um único testcase e devolve o detail *)
let run_testcase (job : job) (workdir : string) (tc : testcase) =
  let image = image_of_lang job.lang in
  let run_cmd = run_cmd_of_lang job.lang in
  let memory = Printf.sprintf "%dm" job.memory_limit_mb in
  let timeout = (job.time_limit_ms / 1000) + 1 in
  (* Escreve o input num ficheiro *)
  let input_file = Printf.sprintf "%s/input_%d.txt" workdir tc.id in
  let oc = open_out input_file in
  output_string oc tc.input ;
  close_out oc ;
  let cmd =
    Printf.sprintf
      "timeout %d docker run --rm --network none --memory %s --cpus 0.5 \
       --read-only --tmpfs /tmp:size=16m -v %s:/work:ro %s sh -c '%s < \
       /work/input_%d.txt' 2>/dev/null"
      timeout memory workdir image run_cmd tc.id
  in
  let start = Unix.gettimeofday () in
  let ic = Unix.open_process_in cmd in
  let output = In_channel.input_all ic in
  let status = Unix.close_process_in ic in
  let time_ms = int_of_float ((Unix.gettimeofday () -. start) *. 1000.) in
  let normalize s = String.trim s in
  let detail_status =
    match status with
    | Unix.WEXITED 0 ->
        if normalize output = normalize tc.output then "accepted"
        else "wrong_answer"
    | Unix.WEXITED 124 -> "time_limit_exceeded"
    | Unix.WEXITED _ -> "runtime_error"
    | _ -> "runtime_error"
  in
  ({testcase_id= tc.id; status= detail_status; time_ms} : detail)

(* Corre todos os testcases e agrega o resultado final *)
let run_all (job : job) (workdir : string) =
  let details : detail list =
    List.map (run_testcase job workdir) job.testcases
  in
  let total = List.length details in
  let accepted =
    List.length
      (List.filter (fun (d : detail) -> d.status = "accepted") details)
  in
  let score = if total = 0 then 0 else accepted * 100 / total in
  let time_ms =
    List.fold_left (fun acc (d : detail) -> max acc d.time_ms) 0 details
  in
  let global_status =
    if accepted = total then "accepted"
    else
      (List.find (fun (d : detail) -> d.status <> "accepted") details).status
  in
  ( { id= job.submission_id
    ; status= global_status
    ; score
    ; time_ms
    ; memory_kb= 0
    ; details }
    : result )
