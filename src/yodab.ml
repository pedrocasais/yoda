open Lwt.Infix
open Redis_lwt

let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp_elt ()) html

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

let getUsers _request =
  Client.connect {host= "valkey"; port= 6379}
  >>= fun conn ->
  Client.scan conn 0
  >>= fun result ->
  match result with
  | _, v -> Dream.html (html_to_string (User.users ~users:v))

let getUserbyId request =
  let id = Dream.param request "id" in
  Client.connect {host= "valkey"; port= 6379}
  >>= fun conn ->
  Client.hgetall conn ("user:" ^ id)
  >>= fun result ->
  match result with
  | x -> Dream.html (html_to_string (User.usersbyID ~users2:x))
(* Dream.html (Users.html2 "ola" request x) *)

let connection = Client.connect {host= "valkey"; port= 6379}

let login_handler request =
  let c = Dream.csrf_tag request in
  print_endline c ;
  Dream.form ~csrf:true request
  >>= fun form ->
  match form with
  | `Ok [("email", email)] -> (
      connection
      >>= fun conn ->
      Client.get conn ("user:username:" ^ email)
      >>= fun data ->
      match data with
      | Some x ->
          print_endline "here" ;
          Client.hgetall conn ("user:" ^ x)
          >>= fun _data' ->
          let page = User.usersbyID ~users2:_data' in
          Dream.html (html_to_string page)
      | None ->
          Dream.html (html_to_string (Index.index ~param:"UPS" ~request)) )
  | _ -> Dream.empty `Bad_Request

let date =
  let today : Unix.tm = Unix.localtime (Unix.time ()) in
  let pp_tm ppf t =
    Format.fprintf ppf "%4d-%02d-%02dT%02d:%02d:%02dZ"
      (t.Unix.tm_year + 1900) (t.Unix.tm_mon + 1) t.Unix.tm_mday
      t.Unix.tm_hour t.Unix.tm_min t.Unix.tm_sec
  in
  Format.asprintf "%a" pp_tm today

let register_handler request =
  Dream.form ~csrf:true request
  >>= fun form ->
  match form with
  | `Ok [("email", email)] ->
      (* match Dream.session_field request "admin" with | Some _ -> *)
      connection
      >>= (fun conn ->
      Client.incr conn "user:id"
      >>= fun id ->
      let key = "user:" ^ string_of_int id in
      Client.hset conn key "username" email
      >>= fun _ ->
      Client.hset conn key "role" "user"
      >>= fun _ -> Client.hset conn key "created_at" date )
      >>= fun _ -> Dream.redirect request "/"
  | _ -> Dream.empty `Bad_Request
(* | None -> Dream.html (html_to_string (Index.index "UPS" request) ) *)

let () =
  let app =
    Dream.router
      [ Dream.get "/resources/ocaml-icon.ico" icon_handler
      ; Dream.get "/" (fun request ->
            Dream.html (html_to_string (Index.index ~param:"ola" ~request)) )
      ; Dream.post "/auth/login" login_handler
      ; Dream.post "/auth/register" register_handler
      ; Dream.get "/users" getUsers
      ; Dream.post "/users" getUsers
      ; Dream.get "/users/:id" getUserbyId
      ; Dream.put "/users/:id" (fun request ->
            Dream.html (html_to_string (Index.index ~param:"ola" ~request)) )
      ; Dream.delete "/users/:id" (fun request ->
            Dream.html (html_to_string (Index.index ~param:"ola" ~request)) )
      ]
    |> Dream.memory_sessions ~lifetime:(60.0 *. 60.0)
    |> Dream.logger
  in
  Dream.run ~interface:"0.0.0.0" app
