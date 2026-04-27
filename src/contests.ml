open Lwt.Infix
open Redis_lwt

let getAllContests conn max =
  let rec aux conn id count acc =
    if count > int_of_string id then Lwt.return acc
    else
      Client.hgetall conn ("contest:" ^ string_of_int count)
      >>= fun lst -> aux conn id (count + 1) (List.rev_append [lst] acc)
  in
  aux conn max 1 []

let getAllProblems conn problems =
  let rec aux conn problems acc =
    if problems = [] then Lwt.return acc
    else
      Client.hgetall conn ("problem:" ^ List.hd problems)
      >>= fun lst -> aux conn (List.tl problems) (List.rev_append [lst] acc)
  in
  aux conn problems []

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

let getContestsIdScoreboard _request = failwith "getContestsIdScoreboard"

let getContestsContestIdSubmissions _request =
  failwith "getContestsIdScoreboard"
(* let id = Dream.param request "contestsId" in Lwt_pool.use Db.pool (fun
   conn -> Client.smembers conn ("contest:"^id) >>= fun res -> let problems =
   function | [] -> [] | x -> x in

   let aux x acc = Client.lrange conn ("problem:" ^ x ^ ":submissions") 0
   (-1) >>= fun r -> Lwt.return (List.rev_append r acc ) in let a = List.map
   (fun x -> aux x [] )(problems res) in *)

(* TODO: contesy_id relly neccessary ???? no json *)

let postContestsContestsIdProblems request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "contestsId" in
      Dream.body request
      >>= fun data ->
      let problem = Openapi.problem_of_json data in
      let rec aux (problem : Openapi.problem) id =
        Lwt_pool.use Db.pool (fun conn ->
            Client.unwatch conn
            >>= fun _ ->
            Client.watch conn ["problem:id"]
            >>= fun _ ->
            Client.get conn "problem:id"
            >>= fun current_id ->
            let next_id =
              match current_id with
              | Some x -> int_of_string x + 1
              | None -> 1
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
              [ "SADD"
              ; "contest:" ^ id ^ ":problems"
              ; string_of_int next_id ]
            >>= fun _ ->
            Client.exec conn
            >>= function
            | [] ->
                Dream.log
                  "Error in postContestsContestsIdProblems! Retrying..." ;
                aux problem id
            | [`Status "OK"; `Int n; `Int x] when x > 0 && n >= 1 ->
                let problem_res =
                  Openapi.create_problem ~code:problem.code
                    ~title:problem.title ~time_limit_ms:problem.time_limit_ms
                    ~memory_limit_mb:problem.memory_limit_mb
                    ~description:problem.description
                    ~input_spec:problem.input_spec
                    ~output_spec:problem.output_spec ()
                in
                Dream.json ~code:201
                  ~headers:[("Content-Type", "application/json")]
                  (Openapi.json_of_problem problem_res)
            | _ ->
                Dream.json ~code:200
                  ~headers:[("Content-Type", "application/json")]
                  "Erro" )
      in
      aux problem id )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

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
              >>= fun lst ->
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
                  | Some x -> Openapi.json_of_contestsIdPutRequestStatus x
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
                  Dream.json ~code:200
                    ~headers:[("Content-Type", "application/json")]
                    "Erro" ) ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

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
                | reply -> (
                  match reply with
                  | [`Status "OK"; `Int n] when n >= 1 ->
                      let contest_res =
                        Openapi.create_contestsPostRequest
                          ~title:contest.title
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
                      Dream.json ~code:200
                        ~headers:[("Content-Type", "application/json")]
                        "Erro" ) )
          in
          aux contest ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

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
