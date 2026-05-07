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
    ; ("language", Job.string_of_lang job.lang)
    ; ("source_code", job.source_code) ]

let process_job job_str =
  match Job.parse_job job_str with
  | None -> Lwt_io.printf "Erro: JSON inválido\n%!"
  | Some (job : Job.job) -> (
      Lwt_io.printf "Job recebido: submission %d lang %s\n%!"
        job.submission_id
        (Job.string_of_lang job.lang)
      >>= fun () ->
      Lwt_pool.use Db.pool (fun conn -> persist_solution conn job)
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
