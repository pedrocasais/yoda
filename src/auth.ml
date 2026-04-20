open Lwt.Infix
open Redis_lwt

let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp_elt ()) html

let rec aux cursor acc conn pattern =
  if cursor = 0 then Lwt.return acc
  else
    Client.scan conn cursor ~pattern
    >>= fun (next, lst) -> aux next (acc @ lst) conn pattern

let rec userExist conn target = function
  | [] -> Lwt.return false
  | h :: t ->
      Client.hget conn h "username"
      >>= fun data ->
      if data = Some target then Lwt.return true else userExist conn target t

let postAuthRegister request =
  let pattern = "user:*" in
  Dream.body request
  >>= fun data ->
  let user = Openapi.user_of_json data in
  Lwt_pool.use Db.pool (fun conn ->
      Client.scan conn 0 ~pattern
      >>= fun (next_cursor, users) ->
      aux next_cursor users conn pattern
      >>= fun allusers ->
      userExist conn user.username allusers
      >>= fun res ->
      if res then
        Dream.html (html_to_string (Index.index ~param:"ja exites" ~request))
      else
        Client.incr conn "u:id"
        >>= (fun id ->
        let key = "user:" ^ string_of_int id in
        Client.hset conn key "username" user.username
        >>= fun _ ->
        Client.hset conn key "role" (Openapi.UserRole.to_json user.role)
        >>= fun _ -> Client.hset conn key "created_at" user.created_at )
        >>= fun _ -> Dream.redirect request "/" )

let postAuthLogin request =
  let pattern = "user:*" in
  Dream.body request
  >>= fun data ->
  let user = Openapi.user_of_json data in
  Lwt_pool.use Db.pool (fun conn ->
      Client.scan conn 0 ~pattern
      >>= fun (next_cursor, users) ->
      aux next_cursor users conn pattern
      >>= fun allusers -> userExist conn user.username allusers )
  >>= fun res ->
  if res then
    (*existe entra*)
    Dream.html (html_to_string (Index.index ~param:"exites" ~request))
  else
    Dream.html (html_to_string (Index.index ~param:"nao exisgte" ~request))
