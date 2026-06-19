(** Worker principal do YodaC.

    Este módulo implementa o loop de processamento de submissões —
    consome jobs da fila do Valkey, compila e executa o código,
    e escreve o resultado de volta no Valkey. *)

open Lwt.Infix
open Redis_lwt

(** [exist] é um tipo que identifica se existe um problema nas scoreboard de um dado user
  - NoProblems, denota que o utilizador não está na scoreboard, junta um problema de tipo [Openapi.json_]
  - SameProblem, identifica que o utilizador fez uma submissão num problema já registado, de tipo [string] contendo as informações na scoreboard do user 
  - NewProblem, identifica utilizador que fez uma submissão num problema não registado na scoreboard, tipo [string] contendo a informação da scoreboard do user  *)
type exist =
  | NoProblems of Openapi.json_
  | SameProblem of string
  | NewProblem of string

(** [getScoreboard conn] obtém o scoreboard para um dado concurso por [id]
  @param conn conexão há base de dados
  @param id id de concurso
  @return devolve uma [string list Lwt.t] com a scoreboard de um concurso *)
let getScoreboard conn id =
  Client.zrange conn ("contest:" ^ id ^ ":scoreboard") 0 (-1)
  >>= fun x ->
  let rec aux acc = function
    | [] -> Lwt.return (List.rev acc)
    | `Bulk (Some score) :: tl -> aux (score :: acc) tl
    | _ -> Lwt.return (List.rev acc)
  in
  aux [] x

(** [checkExists lst (job : Job.job) (result : Job.result)] verifica se um utilizador já está presente no scoreboard
  @param lst [string list] scoreboard de um concurso
  @param job [Job.job] job recebido para avaliação
  @param result [Job.result] resultado da avaliação de um job
  @return devolve uma opção do tipo [exist], caso o utilizador não exista [NoProblems], caso exista e submeteu um problema que não esteja presente na scoreboarad [NewProblem], caso contrário [SameProblem] *)
let checkExists lst (job : Job.job) (result : Job.result) =
  let score_team =
    List.find_opt
      (fun j ->
        string_of_int job.user_id
        = List.nth
            ( Openapi.json__of_json j
            |> Yojson.Safe.Util.member "team"
            |> Yojson.Safe.to_string |> String.split_on_char '\"' )
            1 )
      lst
  in
  match score_team with
  | Some x ->
      let problem_id =
        Yojson.Safe.from_string x
        |> Yojson.Safe.Util.member "problems"
        |> Yojson.Safe.Util.member (string_of_int job.problem_id)
        |> Yojson.Safe.to_string
      in
      if problem_id = "null" then NewProblem (Option.get score_team)
      else SameProblem (Option.get score_team)
  | None ->
      let newproblem =
        `Assoc
          [ ( string_of_int job.problem_id
            , `Assoc
                [ ( "solved"
                  , if result.status = "accepted" then `Bool true
                    else `Bool false )
                ; ("attempts", `Int 1)
                ; ("time", `Int 0) ] ) ]
      in
      NoProblems newproblem

(** [getSolved (result : Job.result) x] atualiza o parâmetro [solved] do scoreboard 
 @param result [Job.result] resultado de uma avaliação
 @param x [string] de informações do utilizador no scoreboard 
 @return número de problemas resolvidos *)
let getSolved (result : Job.result) x =
  if result.status = "accepted" then
    1
    + ( Yojson.Safe.from_string x
      |> Yojson.Safe.Util.member "solved"
      |> Yojson.Safe.Util.to_int )
  else
    Yojson.Safe.from_string x
    |> Yojson.Safe.Util.member "solved"
    |> Yojson.Safe.Util.to_int

(** [makeScoreboardEntry (job : Job.job) (result : Job.result) exist] converte uma string numa [Openapi.scoreboardEntry] 
  @param job [Job.job] job recebido para avaliação
  @param result [Job.result] resultado da avaliação de um job
  @param exist [exist string] tipo de problema a adicionar no scoreboard 
  @return devolve [Openapi.scoreboardEntry] para adicionar há scoreboard  *)
let makeScoreboardEntry (job : Job.job) (result : Job.result) = function
  | SameProblem x ->
      let old_problems =
        Yojson.Safe.from_string x
        |> Yojson.Safe.Util.member "problems"
        |> Yojson.Safe.Util.to_assoc
      in
      let attempts =
        match List.assoc_opt (string_of_int job.problem_id) old_problems with
        | Some prev ->
            prev
            |> Yojson.Safe.Util.member "attempts"
            |> Yojson.Safe.Util.to_int
        | None -> 0
      in
      let new_problem =
        `Assoc
          [ ("solved", `Bool (result.status = "accepted"))
          ; ("attempts", `Int (attempts + 1))
          ; ("time", `Int 0) ]
      in
      Openapi.create_scoreboardEntry
        ~team:(string_of_int job.user_id)
        ~solved:(getSolved result x) ~penalty:0
        ~problems:
          (Openapi.json__of_json
             (Yojson.Safe.to_string
                (`Assoc
                   ( (string_of_int job.problem_id, new_problem)
                   :: List.filter
                        (fun (k, _) -> k <> string_of_int job.problem_id)
                        old_problems ) ) ) )
        ()
  | NewProblem x ->
      let newproblem =
        `Assoc
          [ ("solved", `Bool (result.status = "accepted"))
          ; ("attempts", `Int 1)
          ; ("time", `Int 0) ]
      in
      let oldproblems =
        Yojson.Safe.from_string x
        |> Yojson.Safe.Util.member "problems"
        |> Yojson.Safe.Util.to_assoc
      in
      Openapi.create_scoreboardEntry
        ~team:(string_of_int job.user_id)
        ~solved:(getSolved result x) ~penalty:0
        ~problems:
          (Openapi.json__of_json
             (Yojson.Safe.to_string
                (`Assoc
                   ( oldproblems
                   @ [(string_of_int job.problem_id, newproblem)] ) ) ) )
        ()
  | NoProblems x ->
      Openapi.create_scoreboardEntry
        ~team:(string_of_int job.user_id)
        ~solved:(if result.status = "accepted" then 1 else 0)
        ~penalty:0 ~problems:x ()

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
    [ ("id", string_of_int result.id)
    ; ("status", result.status)
    ; ("score", string_of_int result.score)
    ; ("time_ms", string_of_int result.time_ms)
    ; ("memory_kb", string_of_int result.memory_kb)
    ; ("details", details) ]

(** Escreve o resultado da submissão no Valkey, adiciona ao scoreboard e imprime no stdout.
    Usa uma transação para garantir que todos os dados são guardados e a pool de conexões definido em {!Db}. *)
let write_result (result : Job.result) (job : Job.job) =
  let aux conn contest_id str details =
    Client.multi conn
    >>= fun _ ->
    Client.send_custom_request conn
      [ "HSET"
      ; "submission:" ^ string_of_int result.id
      ; "id"
      ; string_of_int result.id
      ; "status"
      ; result.status
      ; "score"
      ; string_of_int result.score
      ; "time_ms"
      ; string_of_int result.time_ms
      ; "memory_kb"
      ; string_of_int result.memory_kb
      ; "details"
      ; details ]
    >>= fun _ ->
    ( match str with
      | SameProblem x ->
          Client.send_custom_request conn
            [ "ZADD"
            ; "contest:" ^ Option.get contest_id ^ ":scoreboard"
            ; string_of_int (getSolved result x)
            ; Openapi.json_of_scoreboardEntry
                (makeScoreboardEntry job result (SameProblem x))
            ; "ZREM"
            ; "contest:" ^ Option.get contest_id ^ ":scoreboard"
            ; x ]
      | NewProblem x ->
          Client.send_custom_request conn
            [ "ZADD"
            ; "contest:" ^ Option.get contest_id ^ ":scoreboard"
            ; string_of_int (getSolved result x)
            ; Openapi.json_of_scoreboardEntry
                (makeScoreboardEntry job result (NewProblem x))
            ; "ZREM"
            ; "contest:" ^ Option.get contest_id ^ ":scoreboard"
            ; x ]
      | NoProblems x ->
          Client.send_custom_request conn
            [ "ZADD"
            ; "contest:" ^ Option.get contest_id ^ ":scoreboard"
            ; string_of_float (if result.status = "accepted" then 1. else 0.)
            ; Openapi.json_of_scoreboardEntry
                (makeScoreboardEntry job result (NoProblems x)) ] )
    >>= fun _ ->
    Client.exec conn
    >>= fun _ ->
    Lwt_io.printf "Resultado: submission %d -> %s (%d%%)\n%!" result.id
      result.status result.score
  in
  Lwt_pool.use Db.pool (fun conn ->
      Client.hget conn
        ("problem:" ^ string_of_int job.problem_id)
        "contest_id"
      >>= fun contest_id ->
      getScoreboard conn (Option.get contest_id)
      >>= fun lst ->
      let details =
        `List (List.map Openapi.yojson_of_submissionDetails result.details)
        |> Yojson.Safe.to_string
      in
      aux conn contest_id (checkExists lst job result) details )

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
               [ ("id", `Int (int_of_string tc_id))
               ; ("input", `String (get "input"))
               ; ("output", `String (get "output"))
               ; ("is_sample", `Bool (bool_of_string (get "is_sample"))) ] ) )
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
      [ ("submission_id", `Int (int_of_string submission_id))
      ; ("user_id", `Int user_id)
      ; ("problem_id", `Int problem_id)
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
      let workdir, src = Compiler_v2.prepare_workdir job in
      match Compiler_v2.compile job workdir src with
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
            job
      | Ok _ ->
          let result = Docker_runner_v2.run_all job workdir in
          write_result result job )

(** Loop principal do worker.
    Bloqueia com [BRPOP] na fila [submission:job] até haver um job,
    processa-o com {!process_job} e repete indefinidamente. *)
let rec worker () =
  Lwt_pool.use Db.pool (fun conn -> Client.brpop conn ["submission:job"] 0)
  >>= function
  | None -> worker ()
  | Some (_, job_str) -> process_job job_str >>= fun () -> worker ()

(** Ponto de entrada do YodaC.
    Imprime o endereço do Valkey e arranca o {!worker}. *)
let run () =
  Lwt_main.run
    ( Lwt_io.printf "YodaC worker iniciado em %s:%d...\n%!" Db.host Db.port
    >>= fun () -> worker () )
