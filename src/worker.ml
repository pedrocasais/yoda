open Lwt.Infix
open Redis_lwt

let write_result (result : Job.result) =
  let key = Printf.sprintf "submission:%d" result.id in
  Lwt_pool.use Db.pool (fun conn ->
      Client.hset conn key "json" (Job.result_to_json result) )
  >>= fun _ ->
  Lwt_io.printf "Resultado: submission %d -> %s (%d%%)\n%!" result.id
    result.status result.score

let persist_job conn (job : Job.job) job_str =
  let key = Printf.sprintf "submission:%d" job.submission_id in
  let testcases_json =
    Yojson.Safe.to_string
      (`List (List.map Openapi.yojson_of_testCase job.testcases))
  in
  Client.hset conn key "json" job_str
  >>= fun _ ->
  Client.hset conn key "submission_id" (string_of_int job.submission_id)
  >>= fun _ ->
  Client.hset conn key "contest_id" (string_of_int job.contest_id)
  >>= fun _ ->
  Client.hset conn key "problem_id" (string_of_int job.problem_id)
  >>= fun _ ->
  Client.hset conn key "language" (Job.string_of_lang job.lang)
  >>= fun _ ->
  Client.hset conn key "source_code" job.source_code
  >>= fun _ ->
  Client.hset conn key "time_limit_ms" (string_of_int job.time_limit_ms)
  >>= fun _ ->
  Client.hset conn key "memory_limit_mb" (string_of_int job.memory_limit_mb)
  >>= fun _ -> Client.hset conn key "testcases" testcases_json

let process_job job_str =
  match Job.parse_job job_str with
  | None -> Lwt_io.printf "Erro: JSON inválido\n%!"
  | Some (job : Job.job) -> (
      Lwt_io.printf "Job recebido: submission %d lang %s\n%!"
        job.submission_id
        (Job.string_of_lang job.lang)
      >>= fun () ->
      Lwt_pool.use Db.pool (fun conn -> persist_job conn job job_str)
      >>= fun _ ->
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
  Lwt_pool.use Db.pool (fun conn -> Client.brpop conn ["jobs"] 0)
  >>= function
  | None -> worker ()
  | Some (_, job_str) -> process_job job_str >>= fun () -> worker ()

let run () =
  Lwt_main.run
    ( Lwt_io.printf "YodaC worker iniciado em %s:%d...\n%!" Db.host Db.port
    >>= fun () -> worker () )
