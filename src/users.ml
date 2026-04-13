open Lwt.Infix
open Redis_lwt

let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp_elt ()) html

let rec aux conn cursor acc pattern =
  if cursor = 0 then Lwt.return acc
  else
    Client.scan conn cursor ~pattern
    >>= fun (next_cursor, lst) -> aux conn next_cursor (acc @ lst) pattern

let deleteUsersId request =
  let id = Dream.param request "id" in
  Lwt_pool.use Db.pool (fun conn -> Client.del conn ["user:" ^ id])
  >>= function
  | 1 ->
      Dream.response ~status:`OK
        ~headers:[("Content-Type", "text/plain")]
        "dleted"
      |> Lwt.return
  | 0 | _ ->
      Dream.response ~status:`Not_Found
        ~headers:[("Content-Type", "text/plain")]
        "User not found\n"
      |> Lwt.return

let putUsersId request =
  let id = Dream.param request "id" in
  Dream.body request
  >>= fun _update ->
  Lwt_pool.use Db.pool (fun conn -> Client.hgetall conn ("user:" ^ id))
  >>= function
  | [] ->
      Dream.response ~status:`Not_Found
        ~headers:[("Content-Type", "text/plain")]
        "User not found\n"
      |> Lwt.return
  | _ ->
      (*TODO: UPPDATE HERE ||*)
      Dream.response ~status:`Not_Found
        ~headers:[("Content-Type", "text/plain")]
        "FOUND"
      |> Lwt.return

let getUsersId request =
  let id = Dream.param request "id" in
  Lwt_pool.use Db.pool (fun conn -> Client.hgetall conn ("user:" ^ id))
  >>= function
  | [] ->
      Dream.response ~status:`Not_Found
        ~headers:[("Content-Type", "text/plain")]
        "User not found\n"
      |> Lwt.return
  | data ->
      Dream.response ~status:`OK
        ~headers:[("Content-Type", "text/plain")]
        (String.concat "" (List.map (fun (k, v) -> k ^ ": " ^ v) data))
      |> Lwt.return

let postUsers _request = failwith "postUsers"

let getUsers _request =
  let pattern = "user:*" in
  Lwt_pool.use Db.pool (fun conn -> Client.scan conn 0 ~pattern:pattern
  >>= fun (cursor,users) ->
  aux conn  cursor users pattern) >>= fun data -> 
    
  Dream.html (html_to_string (User.users ~users:data))
