open Lwt.Infix
open Redis_lwt

(* make list of submission details based on tests from determined problem *)
let makeTestCaseList lst =
  List.fold_left
    (fun acc x ->
      let subdetail =
        Openapi.create_submissionDetails
          ~testcase_id:(int_of_string (List.assoc "id" x))
          ~status:"" ~time_ms:0 ()
      in
      List.rev_append [Openapi.json_of_submissionDetails subdetail] acc )
    [] lst

(* make list of submission details convert from string to yojson to
   Openapi.submission list*)
let makeSubmissionDetailsList lst =
  Yojson.Basic.Util.to_list (Yojson.Basic.from_string lst)
  |> List.map (fun x ->
      let lst = Yojson.Basic.Util.to_assoc x in
      Openapi.create_submissionDetails
        ~testcase_id:
          (Yojson.Basic.Util.to_int (List.assoc "testcase_id" lst))
        ~status:(Yojson.Basic.Util.to_string (List.assoc "status" lst))
        ~time_ms:(Yojson.Basic.Util.to_int (List.assoc "time_ms" lst))
        () )

(* get submission by id *)
let getSubmissionsId request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "id" in
      Lwt_pool.use Db.pool (fun conn ->
          Client.hgetall conn ("submission:" ^ id) )
      >>= function
      | [] ->
          Dream.json ~code:404
            ~headers:[("Content-Type", "application/json")]
            "Submission not found"
      | lst ->
          let sub =
            Openapi.create_submission ~id:(int_of_string id)
              ~status:(List.assoc "status" lst)
              ~score:(int_of_string (List.assoc "score" lst))
              ~time_ms:(int_of_string (List.assoc "time_ms" lst))
              ~memory_kb:(int_of_string (List.assoc "memory_kb" lst))
              ~details:(makeSubmissionDetailsList (List.assoc "details" lst))
              ()
          in
          Dream.json ~code:200
            ~headers:[("Content-Type", "application/json")]
            (Openapi.json_of_submission sub) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(* post submission *)
let postSubmissions request =
  Lwt.catch
    (fun () ->
      Dream.body request
      >>= fun data ->
      let sub = Openapi.solution_of_json data in
      let rec aux (solution : Openapi.solution) conn testcases =
        Client.unwatch conn
        >>= fun _ ->
        Client.watch conn ["submission:id"]
        >>= fun _ ->
        Client.get conn "submission:id"
        >>= fun current_id ->
        let next_id =
          match current_id with Some x -> int_of_string x + 1 | None -> 1
        in
        let key = "submission:" ^ string_of_int next_id in
        let key2 = "submission:" ^ string_of_int next_id ^ ":solution" in
        Client.multi conn
        >>= fun _ ->
        Client.send_custom_request conn
          ["SET"; "submission:id"; string_of_int next_id]
        >>= fun _ ->
        Client.send_custom_request conn
          [ "HSET"
          ; key
          ; "id"
          ; string_of_int next_id
          ; "status"
          ; "queued"
          ; "score"
          ; "0"
          ; "time_ms"
          ; "0"
          ; "memory_kb"
          ; "0"
          ; "details"
          ; "[" ^ String.concat "," testcases ^ "]" ]
        >>= fun _ ->
        Client.send_custom_request conn
          [ "HSET"
          ; key2
          ; "user_id"
          ; string_of_int solution.user_id
          ; "problem_id"
          ; string_of_int solution.problem_id
          ; "language"
          ; solution.language
          ; "source_code"
          ; solution.source_code ]
        >>= fun _ ->
        Client.send_custom_request conn
          [ "LPUSH"
          ; "user:" ^ string_of_int solution.user_id ^ ":submissions"
          ; string_of_int next_id ]
        >>= fun _ ->
        Client.send_custom_request conn
          [ "LPUSH"
          ; "problem:" ^ string_of_int solution.problem_id ^ ":submissions"
          ; string_of_int next_id ]
        >>= fun _ ->
        Client.send_custom_request conn
          ["LPUSH"; "submission:job"; string_of_int next_id]
        >>= fun _ ->
        Client.exec conn
        >>= function
        | [] ->
            Dream.log "Error in postSubmissions! Retrying..." ;
            aux solution conn testcases
        | [`Status "OK"; `Int sub; `Int sol; `Int l1; `Int l2; `Int l3]
          when sub >= 1 && sol >= 1 && l1 >= 0 && l2 >= 0 && l3 >= 0 ->
            let sub =
              Openapi.create_submission ~id:next_id ~status:"queued" ~score:0
                ~time_ms:0 ~memory_kb:0 ~details:[] ()
            in
            Dream.json ~code:201
              ~headers:[("Content-Type", "application/json")]
              (Openapi.json_of_submission sub)
        | _ ->
            Dream.json ~code:400
              ~headers:[("Content-Type", "application/json")]
              "Erro"
      in
      Lwt_pool.use Db.pool (fun conn ->
          Client.smembers conn
            ("problem:" ^ string_of_int sub.problem_id ^ ":testcases")
          >>= function
          | [] ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                (Printf.sprintf
                   "No tests found for problem:%d. Problem must have tests \
                    for submissions."
                   sub.problem_id )
          | lst -> (
              Helpers.getAllTestCases conn lst
              >>= function lst' -> aux sub conn (makeTestCaseList lst') ) ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )
