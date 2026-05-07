open Lwt.Infix
open Redis_lwt
(* open Yojson.Basic.Util *)


(* let job =
  {|{
    "submission_id": 1,
    "contest_id": 1,
    "problem_id": 1,
    "language": "ocaml",
    "source_code": "print_endline \"Hello World!\"",
    "time_limit_ms": 50000,
    "memory_limit_mb": 256,
    "testcases": [
        {
        "testcase_id": 1,
        "input": "",
        "expected": "Hello World!",
        "is_sample": true
        },
        {
        "testcase_id": 2,
        "input": "",
        "expected": "Hello!",
        "is_sample": true
        }
    ]
  }|} *)
let job =
  {|{
    "submission_id": 1,
    "user_id": 1,
    "problem_id": 1,
    "language": "ocaml",
    "source_code": "print_endline \"Hello World!\"",
    "testcases": [
        {
        "testcase_id": 1,
        "input": "",
        "expected": "Hello World!",
        "is_sample": true
        },
        {
        "testcase_id": 2,
        "input": "",
        "expected": "Hello!",
        "is_sample": true
        }
    ]
  }|}

    let () =

    let conn = Client.connect {host= "127.0.0.1"; port= 6379} in
    let result json =
      conn >>= fun c -> Client.lpush c "jobs" [json]
    in
    let pong = Lwt_main.run (result job) in
    Printf.printf "%i\n" pong

(* let parse_job job =
  try
    let json = Yojson.Basic.from_string job in
    let language = json |> member "language" |> to_string in
    let code = json |> member "code" |> to_string in
    Some (language, code)
  with _ ->
    None 

let rec worker conn =
  Client.brpop conn ["jobs"] 0 >>= function
  | None -> 
    worker conn
  | Some (_queue, job) ->
    match parse_job job with
    | None ->
      Printf.printf "Erro ao fazer parse do JSON\n%!";
      worker conn
    | Some (language, code) ->
      Printf.printf "Linguagem: %s\n" language;
      Printf.printf "Código: %s\n%!" code;
      worker conn


let () =
  let main =
    Client.connect {host = "127.0.0.1"; port = 6379} >>= fun conn ->
    worker conn
  in
  Lwt_main.run main


 *)
