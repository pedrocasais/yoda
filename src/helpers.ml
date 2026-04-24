open Lwt.Infix
open Redis_lwt

type access = Bad_Request | Unauthorized | Forbidden | Ok

(* check is user is admin *)
let checkPrems request next =
  let id_session = Dream.session_field request "user" in
  let aux = function
    | None -> Lwt.return Unauthorized
    | Some id -> (
        Lwt_pool.use Db.pool (fun conn ->
            Client.hget conn ("user:" ^ id) "role" )
        >>= function
        | Some role ->
            if Openapi.userRole_of_json role = Openapi.Admin then
              Lwt.return Ok
            else Lwt.return Forbidden
        | None -> Lwt.return Bad_Request )
  in
  aux id_session
  >>= function
  | Bad_Request ->
      let error =
        Openapi.create_authLoginPostResponse41 ~error:"Bad Request" ()
      in
      Dream.json ~code:400
        ~headers:[("Content-Type", "application/json")]
        (Openapi.json_of_authLoginPostResponse41 error)
  | Unauthorized ->
      let error =
        Openapi.create_authLoginPostResponse41 ~error:"Unauthorized access"
          ()
      in
      Dream.json ~code:401
        ~headers:[("Content-Type", "application/json")]
        (Openapi.json_of_authLoginPostResponse41 error)
  | Forbidden ->
      let error =
        Openapi.create_authLoginPostResponse41
          ~error:"Forbidden - admin only" ()
      in
      Dream.json ~code:403
        ~headers:[("Content-Type", "application/json")]
        (Openapi.json_of_authLoginPostResponse41 error)
  | Ok -> next ()

(* get date *)
let date =
  let today : Unix.tm = Unix.localtime (Unix.time ()) in
  let pp_tm ppf t =
    Format.fprintf ppf "%4d-%02d-%02dT%02d:%02d:%02dZ"
      (t.Unix.tm_year + 1900) (t.Unix.tm_mon + 1) t.Unix.tm_mday
      t.Unix.tm_hour t.Unix.tm_min t.Unix.tm_sec
  in
  Format.asprintf "%a" pp_tm today
