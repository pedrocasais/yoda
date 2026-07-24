open Lwt.Infix

let login_handler next request =
  match Dream.session_field request "user" with
  | Some _ -> next request
  | None ->
      Dream.json
        ~code:401
        ~headers:[("Content-Type", "application/json")]
        "Unauthorized access"

let login_handler_admin next request =
  match Dream.session_field request "user" with
  | Some _ -> Helpers.checkPrems request (fun () -> next request)
  | None ->
      Dream.json
        ~code:401
        ~headers:[("Content-Type", "application/json")]
        "Unauthorized access"

let login_handler_judge next request =
  let open Redis_lwt in
  match Dream.session_field request "user" with
  | Some _ -> Helpers.checkPrems request (fun () ->
      Lwt_pool.use Db.pool (fun conn ->
          Client.hget conn ("user:" ^ Dream.session_id request) "role" )
      >>= function
      | Some role when Openapi.userRole_of_json role = Openapi.Judge ->
          next request
      | _ ->
          Dream.json
            ~code:403
            ~headers:[("Content-Type", "application/json")]
            "Forbidden - judge only" )
  | None ->
      Dream.json
        ~code:401
        ~headers:[("Content-Type", "application/json")]
        "Unauthorized access"

let () =
  let app =
    Dream.router
      [
        Dream.get "/" (fun _request ->
          Dream.html "/")
        (* Additional routes go here *)