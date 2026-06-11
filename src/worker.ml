(** Worker principal do YodaC.

    Este módulo implementa o loop de processamento de submissões —
    consome jobs da fila do Valkey, compila e executa o código,
    e escreve o resultado de volta no Valkey. *)

open Lwt.Infix
open Redis_lwt

(** Escreve múltiplos campos num Hash do Valkey de uma só vez. *)
let hset_fields conn key fields =
  Lwt_list.iter_s
    (fun (field, value) -> Client.hset conn key field value >|= fun _ -> ())
    fields

(** Persiste o resultado final de uma submissão no Valkey.
    Escreve na chave [submission:{id}] os campos status, score,
    time_ms, memory_kb e details. *)
let persist_submission conn (result : Job.result) =
  let key = Printf.sprintf "submission:%d" result.id in
  let details =
    `List (List.map Openapi.yojson_of_submissionDetails result.details)
    |> Yojson.Safe.to_string
  in
  hset_fields conn key
    [ ("id",         string_of_int result.id)
    ; ("status",     result.status)
    ; ("score",      string_of_int result.score)
    ; ("time_ms",    string_of_int result.time_ms)
    ; ("memory_kb",  string_of_int result.memory_kb)
    ; ("details",    details) ]

(** Escreve o resultado no Valkey e imprime no stdout.
    Usa o pool de conexões definido em {!Db}. *)
let write_result (result : Job.result) =
  Lwt_pool.use Db.pool (fun conn -> persist_submission conn result)
  >>= fun _ ->
  Lwt_io.printf "Resultado: submission %d -> %s (%d%%)\n%!"
    result.id result.status result.score

(** Persiste a solução de um job no Valkey.
    Escreve na chave [submission:{id}:solution]. *)
let persist_solution conn (job : Job.job) =
  let key = Printf.sprintf "submission:%d:solution" job.submission_id in
  hset_fields conn key
    [ ("user_id",     string_of_int job.user_id)
    ; ("problem_id",  string_of_int job.problem_id)
    ; ("language",    job.lang)
    ; ("source_code", job.source_code) ]

(** Vai buscar a solução de uma submissão ao Valkey.
    @param id identificador da submissão como string
    @return tuplo [(problem_id, user_id, language, source_code)]
    @raise Failure se a submissão não existir *)
let solution id =
  let key = Printf.sprintf "submission:%s:solution" id in
  Lwt_pool.use Db.pool (fun conn -> Client.hgetall conn key)
  >>= fun fields ->
  if fields = [] then Lwt.fail_with "submission not found"
  else
    let get f = List.assoc f fields in
    Lwt.return
      ( int_of_string (get "problem_id")
      , int_of_string (get "user_id")
      , get "language"
      , get "source_code" )

(** Vai buscar os limites de execução de um problema ao Valkey.
    @param problem_id identificador do problema
    @return tuplo [(time_limit_ms, memory_limit_mb)]
    @raise Failure se o problema não existir *)
let problem problem_id =
  let key = Printf.sprintf "problem:%i" problem_id in
  Lwt_pool.use Db.pool (fun conn -> Client.hgetall conn key)
  >>= fun fields ->
  if fields = [] then Lwt.fail_with "problem not found"
  else
    let get f = List.assoc f fields in
    Lwt.return
      ( int_of_string (get "time_limit_ms")
      , int_of_string (get "memory_limit_mb") )

(** Vai buscar todos os casos de teste de um problema ao Valkey.
    Primeiro obtém os IDs com [SMEMBERS], depois faz [HGETALL]
    para cada testcase individualmente.
    @param id identificador do problema
    @return lista de valores JSON dos testcases
    @raise Failure se não existirem testcases *)
let testcases id =
  let key = Printf.sprintf "problem:%i:testcases" id in
  Lwt_pool.use Db.pool (fun conn -> Client.smembers conn key)
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
               [ ("id",        `Int  (int_of_string tc_id))
               ; ("input",     `String (get "input"))
               ; ("output",    `String (get "output"))
               ; ("is_sample", `Bool   (bool_of_string (get "is_sample"))) ]))
      tests

(** Processa uma submissão completa:
    + vai buscar a solução, o problema e os testcases ao Valkey
    + constrói o job e faz o parse
    + compila o código com {!Compiler}
    + executa na sandbox com {!Docker_runner}
    + persiste o resultado com {!write_result}

    Em caso de erro de compilação escreve o resultado com
    status [compile_error] sem executar os testcases. *)
let process_job submission_id =
  solution submission_id
  >>= fun (problem_id, user_id, language, source_code) ->
  problem problem_id
  >>= fun (time_limit_ms, memory_limit_mb) ->
  testcases problem_id
  >>= fun tests ->
  let job_json =
    `Assoc
      [ ("submission_id",   `Int (int_of_string submission_id))
      ; ("user_id",         `Int user_id)
      ; ("problem_id",      `Int problem_id)
      ; ("language",        `String language)
      ; ("source_code",     `String source_code)
      ; ("time_limit_ms",   `Int time_limit_ms)
      ; ("memory_limit_mb", `Int memory_limit_mb)
      ; ("testcases",       `List tests) ]
  in
  let job_str = Yojson.Safe.to_string job_json in
  match Job.parse_job job_str with
  | None -> Lwt_io.printf "Erro: JSON inválido\n%!"
  | Some (job : Job.job) ->
      Lwt_io.printf "Job recebido: submission %d lang %s\n%!"
        job.submission_id job.lang
      >>= fun () ->
      let workdir, src = Compiler.prepare_workdir job in
      (match Compiler.compile job workdir src with
       | Error err ->
           Lwt_io.printf "Erro de compilação: %s\n%!" err >>= fun () ->
           write_result
             { id= job.submission_id; status= "compile_error"
             ; score= 0; time_ms= 0; memory_kb= 0; details= [] }
       | Ok _ ->
           let result = Docker_runner.run_all job workdir in
           write_result result)

(** Loop principal do worker.
    Bloqueia com [BRPOP] na fila [submission:job] até haver um job,
    processa-o com {!process_job} e repete indefinidamente. *)
let rec worker () =
  Lwt_pool.use Db.pool
    (fun conn -> Client.brpop conn ["submission:job"] 0)
  >>= function
  | None              -> worker ()
  | Some (_, job_str) -> process_job job_str >>= fun () -> worker ()

(** Ponto de entrada do YodaC.
    Imprime o endereço do Valkey e arranca o {!worker}. *)
let run () =
  Lwt_main.run
    ( Lwt_io.printf "YodaC worker iniciado em %s:%d...\n%!" Db.host Db.port
    >>= fun () -> worker () )