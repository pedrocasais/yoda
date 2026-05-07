open Lwt.Infix
open Redis_lwt

let host =
  let default = "valkey" in
  Option.value (Sys.getenv_opt "VALKEY_HOST") ~default

let port =
  Option.value (Sys.getenv_opt "VALKEY_PORT") ~default:"6379"
  |> int_of_string

let config = {Client.host; Client.port}

let pool =
  Lwt_pool.create 10
    (fun () -> Client.connect config)
    ~dispose:(fun conn -> Client.quit conn >>= fun _ -> Lwt.return_unit)