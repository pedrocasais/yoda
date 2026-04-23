open Lwt.Infix
open Redis_lwt

let write_result conn (result : Job.result) =
  let key = Printf.sprintf "result:%d" result.id in
  Client.set conn key (Job.result_to_json result)
  >>= fun _ ->
  Lwt_io.printf "Resultado: submission %d -> %s (%d%%)\n%!" result.id
    result.status result.score

let process_job conn job_str =
  match Job.parse_job job_str with
  | None -> Lwt_io.printf "Erro: JSON inválido\n%!"
  | Some (job : Job.job) -> (
      Lwt_io.printf "Job recebido: submission %d lang %s\n%!"
        job.submission_id
        (Job.string_of_lang job.lang)
      >>= fun () ->
      let workdir, src = Compiler.prepare_workdir job in
      match Compiler.compile job workdir src with
      | Error err ->
          Lwt_io.printf "Erro de compilação: %s\n%!" err
          >>= fun () ->
          let result : Job.result =
            { id= job.submission_id
            ; status= "compile_error"
            ; score= 0
            ; time_ms= 0
            ; memory_kb= 0
            ; details= [] }
          in
          write_result conn result
      | Ok _ ->
          let result = Docker_runner.run_all job workdir in
          write_result conn result )

let rec worker conn =
  Client.brpop conn ["jobs"] 0
  >>= function
  | None -> worker conn
  | Some (_, job_str) -> process_job conn job_str >>= fun () -> worker conn

let rec connect_with_retry ~host ~port =
  Lwt.catch
    (fun () -> Client.connect {host; port})
    (function
      | Unix.Unix_error
          ((Unix.ECONNREFUSED | Unix.EHOSTUNREACH | Unix.ENOENT), fn, msg) ->
          Lwt_io.eprintf
            "Valkey unavailable at %s:%d (%s: %s). Retrying in 2s...\n%!"
            host port fn msg
          >>= fun () ->
          Lwt_unix.sleep 2.0 >>= fun () -> connect_with_retry ~host ~port
      | exn -> Lwt.fail exn )

let run ?(host = "127.0.0.1") ?(port = 6379) () =
  Lwt_main.run
    ( connect_with_retry ~host ~port
    >>= fun conn ->
    Lwt_io.printf "YodaC worker iniciado em %s:%d...\n%!" host port
    >>= fun () -> worker conn )
