open Lwt.Infix
open Redis_lwt

let maintenance_key = "yoda:config:maintenance"

let message_key = "yoda:config:maintenance:message"

let is_maintenance_flag value =
  match String.lowercase_ascii value with
  | "1" | "true" | "yes" | "on" | "maintenance" -> true
  | _ -> false

let getStatus _request =
  Lwt_pool.use Db.pool (fun conn ->
      Client.get conn maintenance_key
      >>= fun maintenance ->
      Client.get conn message_key
      >>= fun message ->
      let is_maintenance =
        match maintenance with
        | Some raw -> is_maintenance_flag raw
        | None -> false
      in
      let status =
        if is_maintenance then
          let custom_message =
            match message with
            | Some msg when String.trim msg <> "" -> Some msg
            | _ -> None
          in
          Openapi.Status.create ~status:Openapi.Maintenance
            ~message:
              (Option.value custom_message
                 ~default:"Yoda is in maintenance mode." )
            ()
        else
          let custom_message =
            match message with
            | Some msg when String.trim msg <> "" -> Some msg
            | _ -> None
          in
          Openapi.Status.create ~status:Openapi.Ok
            ~message:
              (Option.value custom_message
                 ~default:"Yoda is running normally." )
            ()
      in
      Dream.json ~code:200
        ~headers:[("Content-Type", "application/json")]
        (Openapi.Status.to_json status) )
