open Lwt.Infix

let stats_handler next request =
  Stats.record_yodab_request () >>= fun () -> next request

let login_handler next request =
  match Dream.session_field request "user" with
  | Some _ -> next request
  | None ->
      Dream.json ~code:401
        ~headers:[("Content-Type", "application/json")]
        "Unauthorized access"

let login_handler_admin next request =
  match Dream.session_field request "user" with
  | Some _ -> Helpers.check_admin_permissions request (fun () -> next request)
  | None ->
      Dream.json ~code:401
        ~headers:[("Content-Type", "application/json")]
        "Unauthorized access"

let login_handler_judge next request =
  match Dream.session_field request "user" with
  | Some _ -> Helpers.check_judge_or_admin_permissions request (fun () -> next request)
  | None ->
      Dream.json ~code:401
        ~headers:[("Content-Type", "application/json")]
        "Unauthorized access"

let run () =
  let app =
    Dream.router
      [ Dream.get "/" (fun _request -> Dream.html "/")
        (* Additional routes go here *)