open Lwt.Infix

let favicon_handler _ =
  Lwt_io.(with_file ~mode:Input "static/resources/ocaml-icon.ico" read)
  >>= fun data ->
  Dream.respond ~headers:[("Content-Type", "image/x-icon")] data

let () =
  let app =
    Dream.router
      [ Dream.get "/favicon.ico" favicon_handler
      ; Dream.get "/" (Dream.from_filesystem "static" "index.html") ]
    |> Dream.logger
  in
  Dream.run ~interface:"0.0.0.0" app
