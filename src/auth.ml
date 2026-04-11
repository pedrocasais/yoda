open Lwt.Infix
open Redis_lwt

let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp_elt ()) html

let rec userExist conn target = function
  | [] -> Lwt.return false
  | h :: t ->
      Client.hget conn h "username"
      >>= fun data ->
      if data = Some target then Lwt.return true else userExist conn target t

let postAuthRegister request =
  Dream.body request
  >>= fun data ->
  let user = Types.user_of_json data in
  Lwt_pool.use Db.pool (fun conn ->
      Client.scan conn 0 ~pattern:"user:*"
      >>= fun (_, users) ->
      userExist conn user.username users
      >>= fun res ->
      if res then
        Dream.html (html_to_string (Index.index ~param:"ja exites" ~request))
      else
        Client.incr conn "u:id"
        >>= (fun id ->
        let key = "user:" ^ string_of_int id in
        Client.hset conn key "username" user.username
        >>= fun _ ->
        Client.hset conn key "role" (Types.UserRole.to_json user.role)
        >>= fun _ -> Client.hset conn key "created_at" user.created_at )
        >>= fun _ -> Dream.redirect request "/" )

let postAuthLogin request =
  Dream.body request
  >>= fun data ->
  let user = Types.user_of_json data in
  Lwt_pool.use Db.pool (fun conn ->
      Client.scan conn 0 ~pattern:"user:*"
      >>= fun (_, users) -> userExist conn user.username users )
  >>= fun res ->
  if res then
    (*existe entra*)
    Dream.html (html_to_string (Index.index ~param:"exites" ~request))
  else
    Dream.html (html_to_string (Index.index ~param:"nao exisgte" ~request))
