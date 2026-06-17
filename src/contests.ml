(**  Concuros e Problemas 

  Neste módulo estão presentes as funções para criar e gerir concursos, assim como ´
  criar problemas ligados a um concurso, 
  o Scroboard e ainda obter submissões de um dado concurso. *)

open Lwt.Infix
open Redis_lwt

(** [getAllContests conn max] obtém todos os concursos da [DB]
@param conn conexão há base de dados
@param max contest:id máximo a pesquisar
@return devolve um lista de listas de tuplos com dados de concursos *)
let getAllContests conn max =
  let rec aux count acc =
    if count > int_of_string max then Lwt.return acc
    else
      Client.hgetall conn ("contest:" ^ string_of_int count)
      >>= fun lst -> aux (count + 1) (List.rev_append [lst] acc)
  in
  aux 1 []

(** [getAllProblems conn problems] obtém os problemas presentes na lista [problems], 
@param conn conexão há base de dados
@param problems [string list] com ids de problemas a obter
@return devolve um lista de listas de tuplos com problemas *)
let getAllProblems conn problems =
  let rec aux acc = function
    | [] -> Lwt.return acc
    | hd :: tl ->
        Client.hgetall conn ("problem:" ^ hd)
        >>= fun lst -> aux (List.rev_append [lst] acc) tl
  in
  aux [] problems

(** [makeContestList lst] converte uma lista de listas de tuplos numa contest list, [Openapi.contest list], 
@param lst [(string*string) list list] com concursos, [Openapi.contest]
@return devolve uma lista de concursos [Openapi.contest list] *)
let makeContestList lst =
  List.fold_left
    (fun acc x ->
      let contest =
        Openapi.create_contest
          ~id:(int_of_string (List.assoc "id" x))
          ~title:(List.assoc "title" x)
          ~description:(List.assoc "description" x)
          ~start_time:(List.assoc "start_time" x)
          ~end_time:(List.assoc "end_time" x)
          ~status:(Openapi.contestStatus_of_json (List.assoc "status" x))
          ()
      in
      List.rev_append [contest] acc )
    [] lst

(** [makeProblemList lst] converte uma lista de listas de tuplos numa problem list, [Openapi.problem list], 
@param lst [(string*string) list list] com problemas, [Openapi.problem]
@return devolve uma lista de problemas [Openapi.problems list] *)
let makeProblemList lst =
  List.fold_left
    (fun acc x ->
      let problem =
        Openapi.create_problem ~code:(List.assoc "code" x)
          ~title:(List.assoc "title" x)
          ~description:(List.assoc "description" x)
          ~time_limit_ms:(int_of_string (List.assoc "time_limit_ms" x))
          ~memory_limit_mb:(int_of_string (List.assoc "memory_limit_mb" x))
          ~input_spec:(List.assoc "input_spec" x)
          ~output_spec:(List.assoc "output_spec" x)
          ()
      in
      List.rev_append [problem] acc )
    [] lst

(** [getAllSubmissions conn problems] obtém as submissões de vários problemas, 
@param conn conexão há base de dados
@param problems [string list] com ids de problemas
@return devolve um lista de listas de tuplos com submissões *)
let getAllSubmissions conn problems =
  (* [aux acc x] obtém todos *)
  let rec aux acc = function
    | [] -> Lwt.return acc
    | hd :: tl ->
        Client.lrange conn ("problem:" ^ hd ^ ":submissions") 0 (-1)
        >>= fun r -> aux (List.rev_append r acc) tl
  in
  let rec aux' acc = function
    | [] -> Lwt.return acc
    | hd :: tl ->
        Client.hgetall conn ("submission:" ^ hd)
        >>= fun lst' -> aux' (List.rev_append [lst'] acc) tl
  in
  aux [] problems >>= fun lst -> aux' [] lst

(** [makeSubmissionList lst] converte uma lista de listas de tuplos numa lista de submissões
 @param lst lista de listas de tuplos com submissões efetuadas
 @return devolve um lista de submissões de tipo [Openapi.submission list]*)
let makeSubmissionList lst =
  List.fold_left
    (fun acc x ->
      let submission =
        Openapi.create_submission
          ~id:(int_of_string (List.assoc "id" x))
          ~status:(List.assoc "status" x)
          ~score:(int_of_string (List.assoc "score" x))
          ~time_ms:(int_of_string (List.assoc "time_ms" x))
          ~memory_kb:(int_of_string (List.assoc "memory_kb" x))
          ~details:
            (Helpers.makeSubmissionDetailsList (List.assoc "details" x))
          ()
      in
      List.rev_append [submission] acc )
    [] lst

(** [getScoreboard conn id] obtém o scoreboard associado a um concurso
 @param conn conexão há base de dados
 @param id concurso com [id] fornecido 
 @return  *)
let getScoreboard conn id =
  Client.zrange conn ("contest:" ^ id ^ ":scoreboard") 0 (-1)
  >>= fun x ->
  let rec aux acc = function
    | [] -> Lwt.return (List.rev acc)
    | `Bulk (Some score) :: tl -> aux (score :: acc) tl
    | _ -> Lwt.return (List.rev acc)
  in
  aux [] x

(** [makeScoreboardEntryList lst] converte uma string num scoreboard associado a um concurso com [id], parâmetro da rota.
@param lst [string list] do scoreboard
@return  uma list de entradas do scoreboard de tipo [Openapi.scoreboardEntry list]*)
let makeScoreboardEntryList lst =
  List.fold_left
    (fun acc x ->
      let a =
        Openapi.create_scoreboardEntry
          ~team:
            (List.nth
               (String.split_on_char '\"'
                  ( Yojson.Safe.from_string x
                  |> Yojson.Safe.Util.member "team"
                  |> Yojson.Safe.to_string ) )
               1 )
          ~solved:
            (int_of_float
               (float_of_string
                  ( Yojson.Safe.from_string x
                  |> Yojson.Safe.Util.member "solved"
                  |> Yojson.Safe.to_string ) ) )
          ~penalty:
            (int_of_string
               ( Yojson.Safe.from_string x
               |> Yojson.Safe.Util.member "penalty"
               |> Yojson.Safe.to_string ) )
          ~problems:
            (Openapi.json__of_json
               ( Yojson.Safe.from_string x
               |> Yojson.Safe.Util.member "problems"
               |> Yojson.Safe.to_string ) )
          ()
      in
      List.rev_append [a] acc )
    [] lst

(** [getContestsIdScoreboard request] devolve as scoreboard associado a um concurso com [id], parâmetro da rota.
 @return 200 OK, se for concluído com sucesso, devolve o scoreboard de tipo [Openapi.scoreboardEntry list]; 404 Not Found, se o scoreboard não existir para esse concurso; 500 Internal Server Error, erro. *)
let getContestsIdScoreboard request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "id" in
      Lwt_pool.use Db.pool (fun conn ->
          getScoreboard conn id
          >>= function
          | [] ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                "No Scoreboard"
          | x ->
              Dream.json ~code:200
                ~headers:[("Content-Type", "application/json")]
                (Openapi.json_of_contestsIdScoreboardGetResponse2
                   (makeScoreboardEntryList x) ) ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [getContestsContestIdSubmissions request] devolve as submissões associadas a um concurso com [id], parâmetro da rota.
 @return 200 OK, se for concluído com sucesso, devolve as submissões de tipo [Openapi.submission list]; 404 Not Found, se o concurso/problema não existir ; 500 Internal Server Error, erro. *)
let getContestsContestIdSubmissions request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "contestId" in
      Lwt_pool.use Db.pool (fun conn ->
          Client.smembers conn ("contest:" ^ id ^ ":problems")
          >>= function
          | [] ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                "No problems/submissions found for that contest."
          | lst ->
              (* make sub list *)
              getAllSubmissions conn lst
              >>= fun sublist ->
              Dream.json ~code:200
                ~headers:[("Content-Type", "application/json")]
                (Openapi.json_of_contestsContestidSubmissionsGetResponse2
                   (makeSubmissionList sublist) ) ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [postContestsContestsIdProblems request] cria um problema associado a um concurso com [id], parâmetro da rota.
 @return 201 Created, se for concluído com sucesso, devolve o problema criado de tipo [Openapi.problem]; 404 Not Found, se o concurso não existir ; 500 Internal Server Error, erro. *)
let postContestsContestsIdProblems request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "contestsId" in
      Dream.body request
      >>= fun data ->
      let problem = Openapi.problem_of_json data in
      let rec aux conn (problem : Openapi.problem) id =
        Client.unwatch conn
        >>= fun _ ->
        Client.watch conn ["problem:id"]
        >>= fun _ ->
        Client.get conn "problem:id"
        >>= fun current_id ->
        let next_id =
          match current_id with Some x -> int_of_string x + 1 | None -> 1
        in
        let key = "problem:" ^ string_of_int next_id in
        Client.multi conn
        >>= fun _ ->
        Client.send_custom_request conn
          ["SET"; "problem:id"; string_of_int next_id]
        >>= fun _ ->
        Client.send_custom_request conn
          [ "HSET"
          ; key
          ; "code"
          ; problem.code
          ; "title"
          ; problem.title
          ; "contest_id"
          ; id
          ; "time_limit_ms"
          ; string_of_int problem.time_limit_ms
          ; "memory_limit_mb"
          ; string_of_int problem.memory_limit_mb
          ; "description"
          ; problem.description
          ; "input_spec"
          ; problem.input_spec
          ; "output_spec"
          ; problem.output_spec ]
        >>= fun _ ->
        Client.send_custom_request conn
          ["SADD"; "contest:" ^ id ^ ":problems"; string_of_int next_id]
        >>= fun _ ->
        Client.exec conn
        >>= function
        | [] ->
            Dream.log "Error in postContestsContestsIdProblems! Retrying..." ;
            aux conn problem id
        | [`Status "OK"; `Int n; `Int x] when x > 0 && n >= 1 ->
            let problem_res =
              Openapi.create_problem ~code:problem.code ~title:problem.title
                ~time_limit_ms:problem.time_limit_ms
                ~memory_limit_mb:problem.memory_limit_mb
                ~description:problem.description
                ~input_spec:problem.input_spec
                ~output_spec:problem.output_spec ()
            in
            Dream.json ~code:201
              ~headers:[("Content-Type", "application/json")]
              (Openapi.json_of_problem problem_res)
        | _ ->
            Dream.json ~code:500
              ~headers:[("Content-Type", "application/json")]
              "Erro"
      in
      Lwt_pool.use Db.pool (fun conn ->
          Client.exists conn ("contest:" ^ id)
          >>= function
          | true -> aux conn problem id
          | false ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                "Contest not found" ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [getContestsContestsIdProblems request] devolve uma lista de problemas pertencentes a um concurso com [id] igual ao parâmetro da rota. 
 @return 200 OK, se for concluído com sucesso, devolve os problemas na forma de [Openapi.problems list]; 404 Not Found, se não existirem problemas no concurso com o [id]; 500 Internal Server Error, erro. *)
let getContestsContestsIdProblems request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "contestsId" in
      Lwt_pool.use Db.pool (fun conn ->
          Client.smembers conn ("contest:" ^ id ^ ":problems")
          >>= function
          | [] ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                "No Problems"
          | lst ->
              getAllProblems conn lst
              >>= fun lst' ->
              Dream.json ~code:200
                ~headers:[("Content-Type", "application/json")]
                (Openapi.json_of_contestsContestsidProblemsGetResponse2
                   (makeProblemList lst') ) ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [deleteContestsId request] elimina o concurso pelo [id], parâmetro na rota.
 @return 204 No Content, se for eliminado com sucesso; 404 Not Found, se não existir o concurso com o [id] ou 500 Internal Server Error    *)
let deleteContestsId request =
  Lwt.catch
    (fun () ->
      Helpers.checkPrems request (fun () ->
          let id = Dream.param request "id" in
          Lwt_pool.use Db.pool (fun conn ->
              Client.del conn ["contest:" ^ id] )
          >>= function
          | 0 ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                "Contest not found"
          | _ ->
              Dream.json ~code:204
                ~headers:[("Content-Type", "application/json")]
                "Contest deleted successfully" ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [putContestsId request] atualiza os campos [title, description, start_time, end_time, status] de um concurso identificado pelo parâmetro de rota [id].
 @return 200 OK, se for concluído com sucesso devolve o concurso atualizado de tipo [Openapi.Openapi.contestsIdPutRequest]; 404 Not Found, se não existir o concurso com o [id]; 500 Internal Server Error, erro. *)
let putContestsId request =
  Lwt.catch
    (fun () ->
      Helpers.checkPrems request (fun () ->
          let contest_id = Dream.param request "id" in
          Dream.body request
          >>= fun data ->
          let contest = Openapi.contestsIdPutRequest_of_json data in
          Lwt_pool.use Db.pool (fun conn ->
              let key = "contest:" ^ contest_id in
              Client.hmget conn key
                ["title"; "description"; "start_time"; "end_time"; "status"]
              >>= function
              | [None; None; None; None; None] ->
                  Dream.json ~code:404
                    ~headers:[("Content-Type", "application/json")]
                    "Contest not found"
              | _ as lst -> (
                  Client.send_custom_request conn
                    [ "HSET"
                    ; key
                    ; "title"
                    ; ( match contest.title with
                      | Some x -> x
                      | None -> Option.get (List.nth lst 0) )
                    ; "description"
                    ; ( match contest.description with
                      | Some x -> x
                      | None -> Option.get (List.nth lst 1) )
                    ; "start_time"
                    ; ( match contest.start_time with
                      | Some x -> x
                      | None -> Option.get (List.nth lst 2) )
                    ; "end_time"
                    ; ( match contest.end_time with
                      | Some x -> x
                      | None -> Option.get (List.nth lst 3) )
                    ; "status"
                    ; ( match contest.status with
                      | Some x ->
                          Openapi.json_of_contestsIdPutRequestStatus x
                      | None -> Option.get (List.nth lst 4) ) ]
                  >>= function
                  | `Int _ | `Status "OK" ->
                      let contest_res =
                        Openapi.create_contestsIdPutRequest
                          ~title:
                            ( match contest.title with
                            | Some x -> x
                            | None -> Option.get (List.nth lst 0) )
                          ~description:
                            ( match contest.description with
                            | Some x -> x
                            | None -> Option.get (List.nth lst 1) )
                          ~start_time:
                            ( match contest.start_time with
                            | Some x -> x
                            | None -> Option.get (List.nth lst 2) )
                          ~end_time:
                            ( match contest.end_time with
                            | Some x -> x
                            | None -> Option.get (List.nth lst 3) )
                          ~status:
                            ( match contest.status with
                            | Some x -> x
                            | None ->
                                Openapi.contestsIdPutRequestStatus_of_json
                                  (Option.get (List.nth lst 4)) )
                          ()
                      in
                      Dream.json ~code:200
                        ~headers:[("Content-Type", "application/json")]
                        (Openapi.json_of_contestsIdPutRequest contest_res)
                  | _ ->
                      Dream.json ~code:500
                        ~headers:[("Content-Type", "application/json")]
                        "Erro" ) ) ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [getContestsId request] devolve o concurso com [id] igual ao parâmetro da rota. 
 @return 200 OK, se for concluído com sucesso, devolve o user [Openapi.contest]; 404 Not Found, se não existir o concurso com o [id]; 500 Internal Server Error, erro. *)
let getContestsId request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "id" in
      Lwt_pool.use Db.pool (fun conn ->
          Client.hgetall conn ("contest:" ^ id) )
      >>= function
      | [] ->
          Dream.json ~code:404
            ~headers:[("Content-Type", "application/json")]
            "Contest not found"
      | x ->
          let contest =
            Openapi.create_contest
              ~id:(int_of_string (List.assoc "id" x))
              ~title:(List.assoc "title" x)
              ~description:(List.assoc "description" x)
              ~start_time:(List.assoc "start_time" x)
              ~end_time:(List.assoc "end_time" x)
              ~status:(Openapi.contestStatus_of_json (List.assoc "status" x))
              ()
          in
          Dream.json ~code:200
            ~headers:[("Content-Type", "application/json")]
            (Openapi.json_of_contest contest) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [postContests request] cria um concurso de tipo [Openapi.contest]. 
 @return 200 OK, se for concluído com sucesso, devolve o concurso criado [Openapi.contestsPostRequest]; 500 Internal Server Error, erro. *)
let postContests request =
  Lwt.catch
    (fun () ->
      Helpers.checkPrems request (fun () ->
          Dream.body request
          >>= fun data ->
          let contest = Openapi.contest_of_json data in
          let rec aux (contest : Openapi.contest) =
            Lwt_pool.use Db.pool (fun conn ->
                Client.unwatch conn
                >>= fun _ ->
                Client.watch conn ["contest:id"]
                >>= fun _ ->
                Client.get conn "contest:id"
                >>= fun current_id ->
                let next_id =
                  match current_id with
                  | Some x -> int_of_string x + 1
                  | None -> 1
                in
                let key = "contest:" ^ string_of_int next_id in
                Client.multi conn
                >>= fun _ ->
                Client.send_custom_request conn
                  ["SET"; "contest:id"; string_of_int next_id]
                >>= fun _ ->
                Client.send_custom_request conn
                  [ "HSET"
                  ; key
                  ; "id"
                  ; string_of_int contest.id
                  ; "title"
                  ; contest.title
                  ; "description"
                  ; ( match contest.description with
                    | Some x -> x
                    | None -> "Description." )
                  ; "start_time"
                  ; contest.start_time
                  ; "end_time"
                  ; contest.end_time
                  ; "status"
                  ; Openapi.json_of_contestStatus contest.status ]
                >>= fun _ ->
                Client.exec conn
                >>= function
                | [] ->
                    Dream.log "Error in postAuthRegister! Retrying..." ;
                    aux contest
                | [`Status "OK"; `Int n] when n >= 1 ->
                    let contest_res =
                      Openapi.create_contestsPostRequest ~title:contest.title
                        ~description:
                          ( match contest.description with
                          | Some x -> x
                          | None -> "Description." )
                        ~start_time:contest.start_time
                        ~end_time:contest.end_time ()
                    in
                    Dream.json ~code:200
                      ~headers:[("Content-Type", "application/json")]
                      (Openapi.json_of_contestsPostRequest contest_res)
                | _ ->
                    Dream.json ~code:500
                      ~headers:[("Content-Type", "application/json")]
                      "Erro" )
          in
          aux contest ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [getContests _request] devolve todos os concursos registados. 
 @return 200 OK, se for concluído com sucesso, devolve uma lista de concursos [Openapi.contest list]; 404 Not Found, se não existirem concursos ; 500 Internal Server Error, erro. *)
let getContests _request =
  Lwt.catch
    (fun () ->
      Lwt_pool.use Db.pool (fun conn ->
          Client.get conn "contest:id"
          >>= function
          | Some id -> getAllContests conn id
          | None -> Lwt.fail Not_found )
      >>= function
      | x ->
          Dream.json ~code:200
            ~headers:[("Content-Type", "application/json")]
            (Openapi.json_of_contestsGetResponse2 (makeContestList x)) )
    (fun exn ->
      match exn with
      | Not_found ->
          Dream.json ~code:404
            ~headers:[("Content-Type", "application/json")]
            "Contest not found"
      | _ ->
          Dream.json ~code:500
            ~headers:[("Content-Type", "application/json")]
            (Printexc.to_string exn) )
