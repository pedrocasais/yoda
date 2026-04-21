open Lwt.Infix
open Redis_lwt


let rec aux conn cursor acc pattern =
  if cursor = 0 then Lwt.return acc
  else
    Client.scan conn cursor ~pattern
    >>= fun (next_cursor, lst) -> aux conn next_cursor (acc @ lst) pattern

let rec userExist conn target = function
  | [] -> Lwt.return false
  | h :: t ->
      Client.hget conn h "username"
      >>= fun data ->
      if data = Some target then Lwt.return true else userExist conn target t

let deleteUsersId request =
  Lwt.catch
    (fun () ->
      let id_session = Dream.session_field request "user" in
      match id_session with
      | Some _ -> (
          let id = Dream.param request "id" in
          Lwt_pool.use Db.pool (fun conn -> Client.del conn ["user:" ^ id])
          >>= function
          | 1 ->
              Dream.json ~code:204
                ~headers:[("Content-Type", "application/json")]
                "User deleted successfully"
          | 0 | _ ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                "User not found\n" )
          | None ->
              Dream.json ~code:401
                ~headers:[("Content-Type", "application/json")]
                "Unauthorized access" ) 
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

let putUsersId request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "id" in
      let id_session = Dream.session_field request "user" in
      match id_session with
      | Some _ ->
          Dream.body request
          >>= fun update ->
          Lwt_pool.use Db.pool (fun conn ->
              Client.exists conn ("user:" ^ id)
              >>= function
              | false ->
                  Dream.json ~code:404
                    ~headers:[("Content-Type", "application/json")]
                    "User not found\n"
              | true -> (
                  let data = Openapi.usersIdPutRequest_of_json update in
                  (* let data1 = [] |> (fun acc -> match data.role with |
                     Some r -> ("role",Openapi.json_of_usersIdPutRequestRole
                     r ):: acc | None -> acc ) |> fun acc -> match
                     data.username with Some u -> ("username", u ):: acc |
                     None -> acc in

                     Lwt_list.iter_p (fun (f,v) -> Client.hset conn ("user:"
                     ^ id) f v ) data1 >>= fun _ -> *)
                  ( if Option.is_some data.username then
                      Client.hset conn ("user:" ^ id) "username"
                        (Option.get data.username)
                    else Lwt.return_false )
                  >>= fun _ ->
                  ( if Option.is_some data.role then
                      Client.hset conn ("user:" ^ id) "role"
                        (Openapi.json_of_usersIdPutRequestRole
                           (Option.get data.role) )
                    else Lwt.return_false )
                  >>= fun _ ->
                  Client.hmget conn ("user:" ^ id)
                    ["id"; "username"; "role"; "created_at"]
                  >>= function
                  | lst ->
                      let user =
                        Openapi.create_user
                          ~id:(int_of_string (Option.get (List.nth lst 0)))
                          ~username:(Option.get (List.nth lst 1))
                          ~role:
                            (Openapi.userRole_of_json
                               (Option.get (List.nth lst 2)) )
                          ~created_at:(Option.get (List.nth lst 3))
                          ()
                      in
                      Dream.json ~code:200
                        ~headers:[("Content-Type", "application/json")]
                        (Openapi.json_of_user user) ) )
      | None ->
          Dream.json ~code:401
            ~headers:[("Content-Type", "application/json")]
            "Unauthorized access" )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

let getUsersId request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "id" in
      let id_session = Dream.session_field request "user" in
      match id_session with
      | Some _id -> (
          Lwt_pool.use Db.pool (fun conn ->
              Client.hmget conn ("user:" ^ id)
                ["id"; "username"; "role"; "created_at"] )
          >>= function
          | [] ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                "User not found\n"
          | lst ->
              let user =
                Openapi.create_user
                  ~id:(int_of_string (Option.get (List.nth lst 0)))
                  ~username:(Option.get (List.nth lst 1))
                  ~role:
                    (Openapi.userRole_of_json (Option.get (List.nth lst 2)))
                  ~created_at:(Option.get (List.nth lst 3))
                  ()
              in
              Dream.json ~code:200
                ~headers:[("Content-Type", "application/json")]
                (Openapi.json_of_user user) )
      | None ->
          Dream.json ~code:401
            ~headers:[("Content-Type", "application/json")]
            "Unauthorized access" )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

      
(*  TODO: complete *)
let postUsers request =
  let pattern = "user:*" in
  Dream.body request
  >>= fun data ->
  let user = Openapi.user_of_json data in
  Lwt_pool.use Db.pool (fun conn ->
      Client.scan conn 0 ~pattern
      >>= fun (next_cursor, users) ->
      aux conn next_cursor users pattern
      >>= fun allusers ->
      userExist conn user.username allusers
      >>= fun res ->
      if res then Dream.html "ja exites"
      else
        Client.incr conn "u:id"
        >>= (fun id ->
        let key = "user:" ^ string_of_int id in
        Client.hset conn key "username" user.username
        >>= fun _ ->
        Client.hset conn key "role" (Openapi.UserRole.to_json user.role)
        >>= fun _ -> Client.hset conn key "created_at" user.created_at )
        >>= fun _ -> Dream.redirect request "/" )

let getAllUsers conn max =
  let rec aux conn count max (acc : Openapi.usersGetResponse2) =
    if count > max then Lwt.return (List.rev acc)
    else
      Client.hmget conn
        ("user:" ^ string_of_int count)
        ["id"; "username"; "role"; "created_at"]
      >>= function
      | lst ->
          let user =
            Openapi.create_user
              ~id:(int_of_string (Option.get (List.nth lst 0)))
              ~username:(Option.get (List.nth lst 1))
              ~role:(Openapi.userRole_of_json (Option.get (List.nth lst 2)))
              ~created_at:(Option.get (List.nth lst 3))
              ()
          in
          aux conn (count + 1) max (List.rev_append [user] acc)
  in
  aux conn 1 max []

let getUsers request =
  Lwt.catch
    (fun () ->
      let id_session = Dream.session_field request "user" in
      match id_session with
      | Some _id ->
          Lwt_pool.use Db.pool (fun conn ->
              Client.get conn "u:id"
              >>= fun ls -> getAllUsers conn (int_of_string (Option.get ls)) )
          >>= fun lst ->
          Dream.json ~code:200
            ~headers:[("Content-Type", "application/json")]
            (Openapi.json_of_usersGetResponse2 lst)
      | None ->
          Dream.json ~code:401
            ~headers:[("Content-Type", "application/json")]
            "Unauthorized access" )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )
