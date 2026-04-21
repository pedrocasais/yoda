open Lwt.Infix
open Redis_lwt

let rec getAllUsers cursor acc conn pattern =
  if cursor = 0 then Lwt.return acc
  else
    Client.scan conn cursor ~pattern ~count:100
    >>= fun (next, lst) -> getAllUsers next (acc @ lst) conn pattern

let rec userExist conn target = function
  | [] -> Lwt.return_none
  | h :: t ->
      Client.hgetall conn h
      >>= fun data ->
      if List.assoc_opt "username" data = Some target then
        Lwt.return_some data
      else userExist conn target t

(*creates session based on user -> {user: user_id} *)
let sessions uid =
 fun request ->
  match Dream.session_field request "user" with
  | None ->
      Dream.invalidate_session request
      >>= fun _ ->
      Dream.set_session_field request "user" uid >>= fun _ -> Lwt.return_unit
  | Some _username -> Lwt.return_unit

type access = Bad_Request | Unauthorized | Forbidden | Ok

(* check is user is admin *)
let checkPrems = function
  | None -> Lwt.return Unauthorized
  | Some id -> (
      Lwt_pool.use Db.pool (fun conn ->
          Client.hget conn ("user:" ^ id) "role" )
      >>= function
      | Some role ->
          if Openapi.userRole_of_json role = Openapi.Admin then Lwt.return Ok
          else Lwt.return Forbidden
      | None -> Lwt.return Bad_Request )

      (* get date *)
let date =
  let today : Unix.tm = Unix.localtime (Unix.time ()) in
  let pp_tm ppf t =
    Format.fprintf ppf "%4d-%02d-%02dT%02d:%02d:%02dZ"
      (t.Unix.tm_year + 1900) (t.Unix.tm_mon + 1) t.Unix.tm_mday
      t.Unix.tm_hour t.Unix.tm_min t.Unix.tm_sec
  in
  Format.asprintf "%a" pp_tm today

let postAuthRegister request =
  let pattern = "user:*" in
  let id_session = Dream.session_field request "user" in
  Lwt.catch
    (fun () ->
      checkPrems id_session
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
            Openapi.create_authLoginPostResponse41
              ~error:"Unauthorized access" ()
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
      | Ok ->
          Dream.body request
          >>= fun data ->
          let user = Openapi.usersPostRequest_of_json data in
          let rec aux (user : Openapi.usersPostRequest) =
            let created_at = date in
            Lwt_pool.use Db.pool (fun conn ->
                Client.scan conn 0 ~pattern
                >>= fun (next_cursor, users) ->
                getAllUsers next_cursor users conn pattern
                >>= fun allusers ->
                userExist conn user.username allusers
                >>= function
                | Some _lst ->
                    let error =
                      Openapi.create_authLoginPostResponse41
                        ~error:"already exits" ()
                    in
                    Dream.json ~code:400
                      ~headers:[("Content-Type", "application/json")]
                      (Openapi.json_of_authLoginPostResponse41 error)
                | None -> (
                    Client.unwatch conn
                    >>= fun _ ->
                    Client.watch conn ["u:id"]
                    >>= fun _ ->
                    Client.get conn "u:id"
                    >>= fun current_id ->
                    let next_id =
                      match current_id with
                      | Some x -> int_of_string x + 1
                      | None -> 1
                    in
                    let key = "user:" ^ string_of_int next_id in
                    Client.multi conn
                    >>= fun _ ->
                    Client.send_custom_request conn
                      ["SET"; "u:id"; string_of_int next_id]
                    >>= fun _ ->
                    Client.send_custom_request conn
                      [ "HSET"
                      ; key
                      ; "id"
                      ; string_of_int next_id
                      ; "username"
                      ; user.username
                      ; "password"
                      ; user.password
                      ; "role"
                      ; Openapi.json_of_usersPostRequestRole user.role
                      ; "created_at"
                      ; created_at ]
                    >>= fun _ ->
                    Client.exec conn
                    >>= function
                    | [] ->
                        Dream.log "Error in postAuthRegister! Retrying..." ;
                        aux user
                    | reply -> (
                      match reply with
                      | [`Status "OK"; `Int n] when n >= 1 ->
                          let user =
                            Openapi.create_user ~id:next_id
                              ~username:user.username ~role:(Openapi.userRole_of_json (Openapi.json_of_usersPostRequestRole user.role))
                              ~created_at:created_at ()
                          in
                          Dream.json ~code:200
                            ~headers:[("Content-Type", "application/json")]
                            (Openapi.json_of_user user)
                      | _ ->
                          let error =
                            Openapi.create_authLoginPostResponse41
                              ~error:"Erro" ()
                          in
                          Dream.json ~code:500
                            ~headers:[("Content-Type", "application/json")]
                            (Openapi.json_of_authLoginPostResponse41 error) )
                    ) )
          in
          aux user )
    (fun exn ->
      let error =
        Openapi.create_authLoginPostResponse41
          ~error:(Printexc.to_string exn) ()
      in
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Openapi.json_of_authLoginPostResponse41 error) )

let postAuthLogin request =
  let pattern = "user:*" in
  Lwt.catch
    (fun () ->
      Dream.body request
      >>= function
      | data -> (
          let user = Openapi.authLoginPostRequest_of_json data in
          Lwt_pool.use Db.pool (fun conn ->
              Client.scan conn 0 ~pattern ~count:100
              >>= fun (next_cursor, users) ->
              getAllUsers next_cursor users conn pattern
              >>= fun allusers -> userExist conn user.username allusers )
          >>= function
          | Some lst ->
            (* TODO :   hash here *)
            if (Option.get (List.assoc_opt "password" lst)) = user.password then 
              let user =
                Openapi.create_user
                  ~id:(int_of_string (Option.get (List.assoc_opt "id" lst)))
                  ~username:(Option.get (List.assoc_opt "username" lst))
                  ~role:
                    (Openapi.userRole_of_json
                       (Option.get (List.assoc_opt "role" lst)) )
                  ~created_at:(Option.get (List.assoc_opt "created_at" lst))
                  ()
              in
              sessions (string_of_int user.id) request
              >>= fun _ ->
              let res =
                Openapi.create_authToken
                  ~token:(Dream.session_id request)
                  ~user ()
              in
              Dream.json ~code:200
                ~headers:[("Content-Type", "application/json")]
                (Openapi.json_of_authToken res)
            else 
              let error = Openapi.create_authLoginPostResponse41 ~error: "Invalid username or password" () in
              Dream.json ~code:401
                ~headers:[("Content-Type", "application/json")]
                (Openapi.json_of_authLoginPostResponse41 error)
          | None ->
              let error =
                Openapi.create_authLoginPostResponse41
                  ~error:"invalid credentials" ()
              in
              Dream.json ~code:401
                ~headers:[("Content-Type", "application/json")]
                (Openapi.json_of_authLoginPostResponse41 error) ) )
    (fun exn ->
      let error =
        Openapi.create_authLoginPostResponse41
          ~error:(Printexc.to_string exn) ()
      in
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Openapi.json_of_authLoginPostResponse41 error) )
