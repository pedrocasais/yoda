(** Problemas e TesteCases

    Este módulo contém funções para editar problemas e criar/editar testcases de um determinado problema. *)


open Lwt.Infix
open Redis_lwt

(** [makeTestCaseList lst] converte uma lista de lista com tuplos numa [Openapi.testCase list]
@param lst lista com listas de tuplos, contendo as informções de testCases
@return [Openapi.testCase list] *)
let makeTestCaseList lst =
  List.fold_left
    (fun acc x ->
      let testcase =
        Openapi.create_testCase
          ~id:(int_of_string (List.assoc "id" x))
          ~input:(List.assoc "input" x) ~output:(List.assoc "output" x)
          ~is_sample:(bool_of_string (List.assoc "is_sample" x))
          ()
      in
      List.rev_append [testcase] acc )
    [] lst

(** [postProblemsIdTestcases request] cria um novo testCase para o problema com [id] igual ao parâmetro da rota. 
 @return 200 OK, se for concluído com sucesso, devolve o testcase criado com tipo [Openapi.testCase]; 404 Not Found, se o problema não existir; 400 Bad Request ou 500 Internal Server Error, erro. *)
let postProblemsIdTestcases request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "id" in
      Dream.body request
      >>= fun data ->
      let testCase = Openapi.testCase_of_json data in
      let rec aux (testCase : Openapi.testCase) id conn =
        Client.unwatch conn
        >>= fun _ ->
        Client.watch conn ["testcase:id"]
        >>= fun _ ->
        Client.get conn "testcase:id"
        >>= fun current_id ->
        let next_id =
          match current_id with Some x -> int_of_string x + 1 | None -> 1
        in
        let key = "testcase:" ^ string_of_int next_id in
        Client.multi conn
        >>= fun _ ->
        Client.send_custom_request conn
          ["SET"; "testcase:id"; string_of_int next_id]
        >>= fun _ ->
        Client.send_custom_request conn
          ["SADD"; "problem:" ^ id ^ ":testcases"; string_of_int next_id]
        >>= fun _ ->
        Client.send_custom_request conn
          [ "HSET"
          ; key
          ; "id"
          ; string_of_int testCase.id
          ; "input"
          ; testCase.input
          ; "output"
          ; testCase.output
          ; "is_sample"
          ; string_of_bool testCase.is_sample ]
        >>= fun _ ->
        Client.exec conn
        >>= function
        | [] ->
            Dream.log "Error in postProblemsIdTestcases! Retrying..." ;
            aux testCase id conn
        | [`Status "OK"; `Int probtest; `Int test]
          when test > 0 && probtest > 0 ->
            let testcase =
              Openapi.create_testCase ~id:testCase.id ~input:testCase.input
                ~output:testCase.output ~is_sample:testCase.is_sample ()
            in
            Dream.json ~code:200
              ~headers:[("Content-Type", "application/json")]
              (Openapi.json_of_testCase testcase)
        | _ ->
            Dream.json ~code:400
              ~headers:[("Content-Type", "application/json")]
              "Erro"
      in
      Lwt_pool.use Db.pool (fun conn ->
          Client.exists conn ("problem:" ^ id)
          >>= function
          | true -> aux testCase id conn
          | false ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                "Problem not found" ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [getProblemsIdTestcases request] devolve os testcases que pertencem ao problema com [id] igual ao parâmetro da rota. 
 @return 200 OK, se for concluído com sucesso, devolve uma lista de testcases com tipo [Openapi.testCase list]; 404 Not Found, se não existirem testcases para o problema com [id] dado; 500 Internal Server Error, erro. *)
let getProblemsIdTestcases request =
  Lwt.catch
    (fun () ->
      let problem_id = Dream.param request "id" in
      Lwt_pool.use Db.pool (fun conn ->
          Client.smembers conn ("problem:" ^ problem_id ^ ":testcases")
          >>= function
          | [] ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                "Not testCases for problem"
          | lst ->
              Helpers.getAllTestCases conn lst
              >>= fun lst' ->
              Dream.json ~code:200
                ~headers:[("Content-Type", "application/json")]
                (Openapi.json_of_problemsIdTestcasesGetResponse2
                   (makeTestCaseList lst') ) ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [deleteProblemsId request] elimina o problema pelo [id], parâmetro na rota.
 @return 204 No Content, se for eliminado com sucesso; 404 Not Found, se não existir o problema com o [id] ou 500 Internal Server Error    *)
let deleteProblemsId request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "id" in
      Lwt_pool.use Db.pool (fun conn -> Client.del conn ["problem:" ^ id])
      >>= function
      | x when x > 0 ->
          Dream.respond ~code:204 "Problem deleted successfully"
      | _ ->
          Dream.json ~code:404
            ~headers:[("Content-Type", "application/json")]
            "Problem not found" )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [putProblemsId request] atualiza os campos [code, title, time_limit_ms, memory_limit_mb, description, input_spec, output_spec] do problema identificado pelo parâmetro de rota [id].
 @return 200 OK, se for concluído com sucesso devolve o problema atualizado de tipo [Openapi.problem]; 404 Not Found, se não existir o problema com o [id]; 500 Internal Server Error, erro. *)
let putProblemsId request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "id" in
      Dream.body request
      >>= fun data ->
      let problem = Openapi.problem_of_json data in
      let key = "problem:" ^ id in
      Lwt_pool.use Db.pool (fun conn ->
          Client.exists conn key
          >>= function
          | false ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                "Problem not Found"
          | true ->
              Client.hset conn key "code" problem.code
              >>= fun _ ->
              Client.hset conn key "title" problem.title
              >>= fun _ ->
              Client.hset conn key "time_limit_ms"
                (string_of_int problem.time_limit_ms)
              >>= fun _ ->
              Client.hset conn key "memory_limit_mb"
                (string_of_int problem.memory_limit_mb)
              >>= fun _ ->
              Client.hset conn key "description" problem.description
              >>= fun _ ->
              Client.hset conn key "input_spec" problem.input_spec
              >>= fun _ ->
              Client.hset conn key "output_spec" problem.output_spec
              >>= fun _ ->
              let problem =
                Openapi.create_problem ~code:problem.code
                  ~title:problem.title ~time_limit_ms:problem.time_limit_ms
                  ~memory_limit_mb:problem.memory_limit_mb
                  ~description:problem.description
                  ~input_spec:problem.input_spec
                  ~output_spec:problem.output_spec ()
              in
              Dream.json ~code:200
                ~headers:[("Content-Type", "application/json")]
                (Openapi.json_of_problem problem) ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [getProblemsId _request] devolve o problema com [id] igual ao parâmetro da rota. 
 @return 200 OK, se for concluído com sucesso, devolve problema [Openapi.problem]; 404 Not Found, se não existir o [problem:id] ; 500 Internal Server Error, erro. *)
let getProblemsId request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "id" in
      Lwt_pool.use Db.pool (fun conn ->
          Client.hgetall conn ("problem:" ^ id) )
      >>= function
      | [] ->
          Dream.json ~code:404
            ~headers:[("Content-Type", "application/json")]
            "Problem not found"
      | x ->
          let problem =
            Openapi.create_problem ~code:(List.assoc "code" x)
              ~title:(List.assoc "title" x)
              ~time_limit_ms:(int_of_string (List.assoc "time_limit_ms" x))
              ~memory_limit_mb:
                (int_of_string (List.assoc "memory_limit_mb" x))
              ~description:(List.assoc "description" x)
              ~input_spec:(List.assoc "input_spec" x)
              ~output_spec:(List.assoc "output_spec" x)
              ()
          in
          Dream.json ~code:200
            ~headers:[("Content-Type", "application/json")]
            (Openapi.json_of_problem problem) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )
