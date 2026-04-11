open Lwt.Infix
open Redis_lwt

let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp_elt ()) html

let list_to_string l =
  l |> List.map (fun (k, v) -> k ^ ": " ^ v) |> String.concat "\n"

let deleteUsersId request =
  let id = Dream.param request "id" in
  Lwt_pool.use Db.pool (fun conn -> Client.del conn ["user:" ^ id])
  >>= function 
  | 1 ->  
    Dream.response ~status:`OK
      ~headers:[("Content-Type", "text/plain")]
      "dleted"
    |> Lwt.return
  | 0 | _ ->     Dream.response ~status:`Not_Found
      ~headers:[("Content-Type", "text/plain")]
      "User not found\n"
    |> Lwt.return

let putUsersId request =
  let id = Dream.param request "id" in
  Dream.body request
  >>= fun _update ->
  Lwt_pool.use Db.pool (fun conn ->
      Client.scan conn 0 ~pattern:("user:" ^ id)
      >>= function
      | _, [] ->
          Dream.response ~status:`OK
            ~headers:[("Content-Type", "text/plain")]
            "User not found\n"
          |> Lwt.return
      | _, [x] -> (
          Client.hgetall conn x
          >>= function
          | [] ->
              Dream.response ~status:`Not_Found
                ~headers:[("Content-Type", "text/plain")]
                "User not found\n"
              |> Lwt.return
          | data ->
              (* use hset here to update user with _update*)
              Dream.response ~status:`OK
                ~headers:[("Content-Type", "text/plain")]
                (list_to_string data)
              |> Lwt.return )
      | _ ->
          Dream.response ~status:`Bad_Request
            ~headers:[("Content-Type", "text/plain")]
            "Error"
          |> Lwt.return )

let getUsersId request =
  let id = Dream.param request "id" in
  Lwt_pool.use Db.pool (fun conn -> Client.hgetall conn ("user:" ^ id))
  >>= fun data ->
  match data with
  | [] ->
      Dream.response ~status:`Not_Found
        ~headers:[("Content-Type", "text/plain")]
        "User not found\n"
      |> Lwt.return
  | _ ->
      Dream.response ~status:`OK
        ~headers:[("Content-Type", "text/plain")]
        (list_to_string data)
      |> Lwt.return

let postUsers _request = failwith "postUsers"

let getUsers _request =
  Lwt_pool.use Db.pool (fun conn -> Client.scan conn 0 ~pattern:"user:*")
  >>= fun r ->
  let _, r' = r in
  Dream.html (html_to_string (User.users ~users:r'))
