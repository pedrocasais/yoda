open Lwt.Infix
open Redis_lwt


(* let job =
  {|{
    "language": "ocaml",
    "code": "print_endline "OLaaaaaaaaaaaaaa""
  }|}

let () =
  
  let conn = Client.connect {host= "127.0.0.1"; port= 6379} in
  let result json =
    conn >>= fun c -> Client.lpush c "jobs" [json]
  in
  let pong = Lwt_main.run (result job) in
  Printf.printf "%i\n" pong *)

let rec worker conn =
  Client.brpop conn ["jobs"] 0 >>= function
  | None ->
      worker conn
  | Some (_queue, job) ->
      Printf.printf "Job recebido: %s\n%!" job;
      worker conn

let () =
  let main =
    Client.connect {host = "127.0.0.1"; port = 6379} >>= fun conn ->
    worker conn
  in
  Lwt_main.run main



(* let conn = Client.connect{host = "127.0.0.1"; port = 6379} in let result =
   conn >>= fun c -> Redis_lwt.Client.ping c in let pong = Lwt_main.run
   result in Printf.printf "%b\n" pong *)
