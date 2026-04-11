open Lwt.Infix
open Redis_lwt

let config = {Client.host= "valkey"; Client.port= 6379}

let pool =
  Lwt_pool.create 10
    (fun () -> Client.connect config)
    ~dispose:(fun conn -> Client.quit conn >>= fun _ -> Lwt.return_unit)
