open Lwt.Infix
open Redis_lwt

let hset_fields conn key fields =
  Lwt_list.iter_s
    (fun (field, value) -> Client.hset conn key field value >|= fun _ -> ())
    fields

let persist_submission conn (result : Job.result) =
  let key = Printf.sprintf "submission:%d" result.id in
  let details =
    `List (List.map Openapi.yojson_of_submissionDetails result.details)
    |> Yojson.Safe.to_string
  in
  hset_fields conn key
    [ ("id", string_of_int result.id)
    ; ("status", result.status)
    ; ("score", string_of_int result.score)
    ; ("time_ms", string_of_int result.time_ms)
    ; ("memory_kb", string_of_int result.memory_kb)
    ; ("details", details) ]

let write_result (result : Job.result) =
  Lwt_pool.use Db.pool (fun conn -> persist_submission conn result)
  >>= fun _ ->
  Lwt_io.printf "Resultado: submission %d -> %s (%d%%)\n%!" result.id
    result.status result.score

let persist_solution conn (job : Job.job) =
  let key = Printf.sprintf "submission:%d:solution" job.submission_id in
  hset_fields conn key
    [ ("user_id", string_of_int job.user_id)
    ; ("problem_id", string_of_int job.problem_id)
    ; ("language", job.lang)
    ; ("source_code", job.source_code) ]

let solution id =
  let sub_id_sol = Printf.sprintf "submission:%s:solution" id in
  Lwt_pool.use Db.pool (fun conn -> Client.hgetall conn sub_id_sol)
  >>= fun fields ->
  if fields = [] then Lwt.fail_with "submission not found"
  else
    let get f = List.assoc f fields in
    let json =
      `Assoc
        [ ("user_id", `Int (int_of_string (get "user_id")))
        ; ("problem_id", `Int (int_of_string (get "problem_id")))
        ; ("language", `String (get "language"))
        ; ("source_code", `String (get "source_code")) ]
    in
    Lwt.return (Yojson.Safe.to_string json)
  
let problem problem_id =
  let prob_id = Printf.sprintf "problem:%i" problem_id in
  Lwt_pool.use Db.pool (fun conn -> Client.hgetall conn prob_id)
  >>= fun fields ->
  if fields = [] then Lwt.fail_with "problem not found"
  else
    let get f = List.assoc f fields in
    let time_limit_ms = int_of_string (get "time_limit_ms") in
    let memory_limit_mb = int_of_string (get "memory_limit_mb") in
    Lwt.return (time_limit_ms, memory_limit_mb)

let testcases id =
  let prob_id_tc = Printf.sprintf "problem:%i:testcases" id in
  Lwt_pool.use Db.pool (fun conn -> Client.smembers conn prob_id_tc)
  >>= fun tests ->
  if tests = [] then Lwt.fail_with "testcases not found"
  else
    Lwt_list.map_s
      (fun tc_id ->
        let key = Printf.sprintf "testcase:%s" tc_id in
        Lwt_pool.use Db.pool (fun conn -> Client.hgetall conn key)
        >>= fun fields ->
        if fields = [] then
          Lwt.fail_with (Printf.sprintf "testcase %s not found" tc_id)
        else
          let get f = List.assoc f fields in
          Lwt.return
            (`Assoc
               [ ("id", `Int (int_of_string tc_id))
               ; ("input", `String (get "input"))
               ; ("output", `String (get "output"))
               ; ("is_sample", `Bool (bool_of_string (get "is_sample"))) ] ) )
      tests

let process_job submission_id =
  solution submission_id
  >>= fun sol_json ->
  let json = Yojson.Safe.from_string sol_json in
  let open Yojson.Safe.Util in
  let problem_id = json |> member "problem_id" |> to_int in
  let user_id = json |> member "user_id" |> to_int in
  let language = json |> member "language" |> to_string in
  let source_code = json |> member "source_code" |> to_string in
  problem problem_id >>= fun (time_limit_ms, memory_limit_mb) ->
  testcases  problem_id >>= fun tests ->
  let job_json =
    `Assoc
      [ ("submission_id", `Int (int_of_string submission_id))
      ; ("user_id", `Int user_id)
      ; ("problem_id", `Int  problem_id)
      ; ("language", `String language)
      ; ("source_code", `String source_code)
      ; ("time_limit_ms", `Int time_limit_ms)
      ; ("memory_limit_mb", `Int memory_limit_mb)
      ; ("testcases", `List tests) ]
  in
  let job_str = Yojson.Safe.to_string job_json in
  match Job.parse_job job_str with
  | None -> Lwt_io.printf "Erro: JSON inválido\n%!"
  | Some (job : Job.job) -> (
      Lwt_io.printf "Job recebido: submission %d lang %s\n%!"
        job.submission_id job.lang
      >>= fun () ->
      let workdir, src = Compiler.prepare_workdir job in
      match Compiler.compile job workdir src with
      | Error err ->
          Lwt_io.printf "Erro de compilação: %s\n%!" err
          >>= fun () ->
          write_result
            { id= job.submission_id
            ; status= "compile_error"
            ; score= 0
            ; time_ms= 0
            ; memory_kb= 0
            ; details= [] }
      | Ok _ ->
          let result = Docker_runner.run_all job workdir in
          write_result result )

let rec worker () =
  Lwt_pool.use Db.pool (fun conn -> Client.brpop conn ["submission:job"] 0)
  >>= function
  | None -> worker ()
  | Some (_, job_str) -> process_job job_str >>= fun () -> worker ()

let run () =
  Lwt_main.run
    ( Lwt_io.printf "YodaC worker iniciado em %s:%d...\n%!" Db.host Db.port
    >>= fun () -> worker () )
