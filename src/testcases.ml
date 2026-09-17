open Lwt.Infix
open Redis_lwt

(** [putTestcasesTestcaseId request] atualiza os campos [input, output, is_sample] do testcase identificado pelo parâmetro de rota [testcaseId] pertencente ao problema com [id] igual ao parâmetro da rota.
 @return 200 OK, se for concluído com sucesso devolve o testcase atualizado de tipo [Openapi.testCase]; 404 Not Found, se não existir o testcase com o [testcaseId] ou o problema com o [id]; 500 Internal Server Error, erro. *)
let putTestcasesTestcaseId request =
  (fun () ->
    Lwt.catch
      (fun () ->
        Dream.body request
        >>= fun data ->
        let testcase_id = Dream.param request "testcaseId" in
        let testCase = Openapi.testCaseCreateRequest_of_json data in
        Lwt_pool.use Db.pool (fun conn ->
            Client.exists conn ("testcase:" ^ testcase_id)
            >>= function
            | false ->
                Dream.json ~code:404
                  ~headers:[("Content-Type", "application/json")]
                  (Helpers.error_msg "Test case not found.")
            | true ->
                Client.hset conn
                  ("testcase:" ^ testcase_id)
                  "input" testCase.input
                >>= fun _ ->
                Client.hset conn
                  ("testcase:" ^ testcase_id)
                  "output" testCase.output
                >>= fun _ ->
                Client.hset conn
                  ("testcase:" ^ testcase_id)
                  "is_sample"
                  (string_of_bool testCase.is_sample)
                >>= fun _ ->
                Client.hgetall conn ("testcase:" ^ testcase_id)
                >>= fun testcase_data ->
                let updated_testcase =
                  Openapi.create_testCase
                    ~id:(int_of_string testcase_id)
                    ~input:(List.assoc "input" testcase_data)
                    ~output:(List.assoc "output" testcase_data)
                    ~is_sample:
                      (bool_of_string (List.assoc "is_sample" testcase_data))
                    ()
                in
                Dream.json ~code:200
                  ~headers:[("Content-Type", "application/json")]
                  (Openapi.json_of_testCase updated_testcase) ) )
      (fun exn ->
        Dream.json ~code:500
          ~headers:[("Content-Type", "application/json")]
          ( Helpers.error_msg "Internal server error: "
          ^ Printexc.to_string exn ^ "." ) ) )
  |> Helpers.check_admin_permissions request

(** [deleteTestcasesTestcaseId request] remove o testcase identificado pelo parâmetro de rota [testcaseId] pertencente ao problema com [id] igual ao parâmetro da rota.
 @return 204 No Content, se for removido com sucesso; 404 Not Found, se não existir o testcase com o [testcaseId] ou o problema com o [id]; 500 Internal Server Error, erro. *)
let deleteTestcasesTestcaseId request =
  (fun () ->
    Lwt.catch
      (fun () ->
        let testcase_id = Dream.param request "testcaseId" in
        Lwt_pool.use Db.pool (fun conn ->
            Client.exists conn ("testcase:" ^ testcase_id)
            >>= function
            | false ->
                Dream.json ~code:404
                  ~headers:[("Content-Type", "application/json")]
                  (Helpers.error_msg "Test case not found.")
            | true -> (
                Client.keys conn "problem:*:testcases"
                >>= fun keys ->
                let rec remove_from_problem_sets = function
                  | [] -> Lwt.return ()
                  | key :: rest ->
                      Client.sismember conn key testcase_id
                      >>= fun present ->
                      if present then
                        Client.srem conn key testcase_id
                        >>= fun _ -> remove_from_problem_sets rest
                      else remove_from_problem_sets rest
                in
                remove_from_problem_sets keys
                >>= fun _ ->
                Client.del conn ["testcase:" ^ testcase_id]
                >>= function
                | x when x > 0 ->
                    Dream.respond ~code:204 "Test case deleted successfully"
                | _ ->
                    Dream.json ~code:500
                      ~headers:[("Content-Type", "application/json")]
                      (Helpers.error_msg "Failed to delete test case.") ) ) )
      (fun exn ->
        Dream.json ~code:500
          ~headers:[("Content-Type", "application/json")]
          ( Helpers.error_msg "Internal server error: "
          ^ Printexc.to_string exn ^ "." ) ) )
  |> Helpers.check_admin_permissions request
