open Lwt.Infix
open Redis_lwt

let icon_handler _ =
  Lwt_io.(with_file ~mode:Input "./static/resources/ocaml-icon.ico" read)
  >>= fun data ->
  Dream.respond ~headers:[("Content-Type", "image/x-icon")] data

let _sessions uid =
 fun request ->
  match Dream.session_field request "user" with
  | None ->
      Dream.invalidate_session request
      >>= fun _ ->
      Dream.set_session_field request "user" uid
      >>= fun _ ->
      Printf.ksprintf Dream.html "Welcome %s!" (Dream.html_escape uid)
  | Some username ->
      Printf.ksprintf Dream.html "Welcome back, %s!"
        (Dream.html_escape username)

let getUsers request =
  Client.connect {host= "127.0.0.1"; port= 6379}
  >>= fun conn ->
  Client.scan conn 0
  >>= fun result ->
  match result with
  | _,v ->
      Dream.html (Users.html "ola" request v)

let getUserbyId request = 
  let id = Dream.param request "id" in
  Client.connect {host= "127.0.0.1"; port= 6379}
  >>= fun conn ->
  Client.hgetall conn ("user:" ^ id)
  >>= fun result ->
  match result with
  | _x ->
    Dream.html (Index.html "ola" request)
      (* Dream.html (Users.html2 "ola" request x) *)
   
 
let login_handler request =
  Dream.form ~csrf:true request
  >>= fun form ->
  match form with
  | `Ok [("email", email)] ->
      if email = "a@gmail.com" then _sessions email request
      else Dream.html (Index.html "UPS" request)
  | _ -> Dream.empty `Bad_Request

let date =
  let today : Unix.tm = Unix.localtime (Unix.time ()) in
  let pp_tm ppf t =
    Format.fprintf ppf "%4d-%02d-%02dT%02d:%02d:%02dZ"
      (t.Unix.tm_year + 1900) (t.Unix.tm_mon + 1) t.Unix.tm_mday
      t.Unix.tm_hour t.Unix.tm_min t.Unix.tm_sec
  in
  Format.asprintf "%a" pp_tm today

let register_handler  =
 fun request ->
  (* match Dream.session_field request "admin" with
  | Some _ -> *)
      Client.connect {host= "127.0.0.1"; port= 6379}
      >>= fun conn ->
      Client.incr conn "user:id"
      >>= fun id ->
      let key = "user:" ^ string_of_int id in
      Client.hset conn key "username" "username2"
      >>= fun _ ->
      Client.hset conn key "role" "user"
      >>= fun _ ->
      Client.hset conn key "created_at" date
      >>= fun _ -> Dream.redirect request "/"
  (* | None -> Dream.html (Index.html "UPS" request) *)

let () =
  let app =
    Dream.router
      [ Dream.get "/resources/ocaml-icon.ico" icon_handler
      ; Dream.get "/" (fun request -> Dream.html (Index.html "ola" request))
      ; Dream.post "/auth/login" login_handler
      ; Dream.post "/auth/register" register_handler 
      ; Dream.get "/users" (fun request -> getUsers request)
      ; Dream.post "/users" Output.postUsers
      ; Dream.get "/users/:id" getUserbyId
      ; Dream.put "/users/:id" (fun request ->
            Dream.html (Index.html "ola" request) )
      ; Dream.delete "/users/:id" (fun request ->
            Dream.html (Index.html "ola" request) ) ]
    |> Dream.memory_sessions ~lifetime:(60.0 *. 60.0)
    |> Dream.logger
  in
  Dream.run ~interface:"0.0.0.0" ~port:8082 app
