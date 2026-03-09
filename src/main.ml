open Lwt.Infix

let icon_handler _ =
  Lwt_io.(with_file ~mode:Input "./static/resources/ocaml-icon.ico" read)
  >>= fun data ->
  Dream.respond ~headers:[("Content-Type", "image/x-icon")] data

let () =
  let app =
    Dream.router
      [ Dream.get "/resources/ocaml-icon.ico" icon_handler
      ; Dream.get "/" (Dream.from_filesystem "static" "index.html") ]
    |> Dream.logger
  in
  Dream.run ~interface:"0.0.0.0" app
