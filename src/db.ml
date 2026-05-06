open Lwt.Infix
open Redis_lwt

let host =
  let default = if Sys.file_exists "/.dockerenv" then "valkey" else "127.0.0.1" in
  Option.value (Sys.getenv_opt "VALKEY_HOST") ~default

let port =
  Option.value (Sys.getenv_opt "VALKEY_PORT") ~default:"6379"
  |> int_of_string

let config = {Client.host; Client.port}

let pool =
  Lwt_pool.create 10
    (fun () -> Client.connect config)
    ~dispose:(fun conn -> Client.quit conn >>= fun _ -> Lwt.return_unit)