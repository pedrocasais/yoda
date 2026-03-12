open Lwt.Infix
open Redis_lwt


let job =
  {|{
    "language": "ocaml",
    "code": "print_endline "World""
  }|}

let () =
  
  let conn = Client.connect {host= "127.0.0.1"; port= 6379} in
  let result json =
    conn >>= fun c -> Client.lpush c "jobs" [json]
  in
  let pong = Lwt_main.run (result job) in
  Printf.printf "%i\n" pong

(* let conn = Client.connect{host = "127.0.0.1"; port = 6379} in let result =
   conn >>= fun c -> Redis_lwt.Client.ping c in let pong = Lwt_main.run
   result in Printf.printf "%b\n" pong *)
