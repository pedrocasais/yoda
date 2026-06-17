(**  Submissão de soluções 
  
  Neste módulo estão presentes funções que permitem realizar a submissão de soluções para posteriormente serem avaliadas 
  por {!yoda.yodac}*)

open Lwt.Infix
open Redis_lwt

(** [makeTestCaseList lst] converte uma lista de listas de tuplos, testCases do problema da submissão, para uma string list com elementos de tipo [Openapi.submissionDetails],  .
@param lst lista de listas de tuplos, lista com dados de testCases 
@return [string list] constituída por elementos [Openapi.submissionDetails] *)
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

(** [getSubmissionsId request] Obtém uma submissão com o [id], parâmetro da rota.
 @return 200 OK, devolve um submissão com tipo [Openapi.submission]; 404 Not Found, se a submissão não existir; 500 Internal Server Error    *)
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
              ~details:
                (Helpers.makeSubmissionDetailsList
                   (List.assoc "details" lst) )
              ()
          in
          Dream.json ~code:200
            ~headers:[("Content-Type", "application/json")]
            (Openapi.json_of_submission sub) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [postSubmissions request] Cria uma nova submissão com base numa solução.
  Cria uma submissão [Openapi.submission], uma solucao [Openapi.solution] e adiciona aos jobs para avaliação [submission:jobs]
 @return 201 Created, cria um submissão para avaliação; 404 Not Found, se não existir o testcases para o problema em questão; 400 Bad Request ou 500 Internal Server Error    *)
let postSubmissions request =
  Lwt.catch
    (fun () ->
      Dream.body request
      >>= fun data ->
      let sub = Openapi.solution_of_json data in
      let rec aux (solution : Openapi.solution) conn testcases attempt =
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
            if attempt >= 5 then
              Dream.json ~code:500
                ~headers:[("Content-Type", "application/json")]
                "Max retries exceeded"
            else
              let base = 0.05 *. (2.0 *. float_of_int attempt) in
              let diff = Random.float base in
              Dream.log "Error in postSubmissions! Retrying..." ;
              Lwt_unix.sleep (base +. diff)
              >>= fun () -> aux solution conn testcases (attempt + 1)
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
              >>= function lst' -> aux sub conn (makeTestCaseList lst') 0 ) ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )
