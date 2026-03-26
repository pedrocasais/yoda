open Lwt.Infix
open Redis_lwt
open Yojson.Basic.Util


(* let job =
  {|{
    "language": "ocaml",
    "code": "print_endline \"Hello World!\""
    }|}
    
    let () =
    
    let conn = Client.connect {host= "127.0.0.1"; port= 6379} in
    let result json =
      conn >>= fun c -> Client.lpush c "jobs" [json]
    in
    let pong = Lwt_main.run (result job) in
    Printf.printf "%i\n" pong *)
    
    let parse_job job =
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
                
                
                
