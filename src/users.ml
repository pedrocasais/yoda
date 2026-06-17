(** Users  

    Este módulo contém funções para gerir utilizadores, tais como,
    criar, obter um ou todos os utilizadores, atualizar ou eliminar utilizadaores. *)

open Lwt.Infix
open Redis_lwt

(* here siwthch fix this , maybe use auth getAllusers here instead of this
   (only used on postUSers) *)

(* let rec aux conn cursor acc pattern = if cursor = 0 then Lwt.return acc
   else Client.scan conn cursor ~pattern >>= fun (next_cursor, lst) -> aux
   conn next_cursor (acc @ lst) pattern

   let rec userExist conn target = function | [] -> Lwt.return false | h :: t
   -> Client.hget conn h "username" >>= fun data -> if data = Some target
   then Lwt.return true else userExist conn target t *)

(** [getAllUsers conn max] função auxiliar para obter todos os utilizadores da [DB].
@param conn conexão há base de dados
@param max máximo user_id a pesquisar
@return lista de utilizadores [Openapi.user list]
*)
let getAllUsers conn max =
  let rec aux count (acc : Openapi.usersGetResponse2) =
    if count > max then Lwt.return (List.rev acc)
    else
      let () = Dream.log "id --> %d" count in
      Client.hmget conn
        ("user:" ^ string_of_int count)
        ["id"; "username"; "role"; "created_at"]
      >>= function
      | [Some id; Some username; Some role; Some created_at] ->
          let user =
            Openapi.create_user ~id:(int_of_string id) ~username
              ~role:(Openapi.userRole_of_json role)
              ~created_at ()
          in
          aux (count + 1) (List.rev_append [user] acc)
      | _ -> aux (count + 1) acc
  in
  aux 1 []

(** [deleteUsersId request] elimina o utilizador pelo [id], parâmetro na rota.
 @return 204 No Content, se for eliminado com sucesso; 404 Not Found, se não existir o user com o [id] ou 500 Internal Server Error    *)
let deleteUsersId request =
  Lwt.catch
    (fun () ->
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
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [putUsersId request] atualiza os campos [username, role] do utilizador identificado pelo parâmetro de rota [id].
 @return 200 OK, se for concluído com sucesso devolve o user atualizado de tipo [Openapi.user]; 404 Not Found, se não existir o user com o [id]; 400 Bad Request ou 500 Internal Server Error, erro. *)
let putUsersId request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "id" in
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
              let key = "user:" ^ id in
              Client.hmget conn key ["id"; "username"; "role"; "created_at"]
              >>= function
              | lst -> (
                  Client.send_custom_request conn
                    [ "HSET"
                    ; key
                    ; "username"
                    ; ( match data.username with
                      | Some x -> x
                      | None -> Option.get (List.nth lst 1) )
                    ; "role"
                    ; ( match data.role with
                      | Some x -> Openapi.json_of_usersIdPutRequestRole x
                      | None -> Option.get (List.nth lst 2) ) ]
                  >>= function
                  | `Status "OK" | `Int _ ->
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
                        (Openapi.json_of_user user)
                  | _ ->
                      Dream.json ~code:400
                        ~headers:[("Content-Type", "application/json")]
                        "Erro" ) ) ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [getUsersId request] devolve o utilizador com [id] igual ao parâmetro da rota. 
 @return 200 OK, se for concluído com sucesso, devolve o user [Openapi.user]; 404 Not Found, se não existir o user com o [id]; 500 Internal Server Error, erro. *)
let getUsersId request =
  Lwt.catch
    (fun () ->
      let id = Dream.param request "id" in
      Lwt_pool.use Db.pool (fun conn ->
          Client.hmget conn ("user:" ^ id)
            ["id"; "username"; "role"; "created_at"] )
      >>= function
      | [Some id; Some username; Some role; Some created_at] ->
          let user =
            Openapi.create_user ~id:(int_of_string id) ~username
              ~role:(Openapi.userRole_of_json role)
              ~created_at ()
          in
          Dream.json ~code:200
            ~headers:[("Content-Type", "application/json")]
            (Openapi.json_of_user user)
      | _ ->
          Dream.json ~code:404
            ~headers:[("Content-Type", "application/json")]
            "User not found\n" )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )

(** [postUsers request] regista um novo utilizador usando a lógica de autenticação partilhada. *)
let postUsers request = Auth.postAuthRegister request
(* let pattern = "user:*" in Dream.body request >>= fun data -> let user =
   Openapi.user_of_json data in Lwt_pool.use Db.pool (fun conn -> Client.scan
   conn 0 ~pattern >>= fun (next_cursor, users) -> aux conn next_cursor users
   pattern >>= fun allusers -> userExist conn user.username allusers >>= fun
   res -> if res then Dream.html "ja exites" else Client.incr conn "u:id" >>=
   (fun id -> let key = "user:" ^ string_of_int id in Client.hset conn key
   "username" user.username >>= fun _ -> Client.hset conn key "role"
   (Openapi.UserRole.to_json user.role) >>= fun _ -> Client.hset conn key
   "created_at" user.created_at ) >>= fun _ -> Dream.redirect request "/"
   ) *)

(** [getUsers _request] devolve todos os utilizadores registados. 
 @return 200 OK, se for concluído com sucesso, devolve uma lista de users [Openapi.user list]; 404 Not Found, se não existirem users ; 500 Internal Server Error, erro. *)
let getUsers _request =
  Lwt.catch
    (fun () ->
      Lwt_pool.use Db.pool (fun conn ->
          Client.get conn "user:id"
          >>= function
          | None ->
              Dream.json ~code:404
                ~headers:[("Content-Type", "application/json")]
                "Users not Found"
          | Some max_id ->
              getAllUsers conn (int_of_string max_id)
              >>= fun lst ->
              Dream.json ~code:200
                ~headers:[("Content-Type", "application/json")]
                (Openapi.json_of_usersGetResponse2 lst) ) )
    (fun exn ->
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Printexc.to_string exn) )
