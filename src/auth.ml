open Lwt.Infix
open Redis_lwt

(* define argon2 variables for hashing *)
let t_cost = 2

and m_cost = 65536

and parallelism = 1

and hash_len = 32

and salt_len = 32

(* get encoded lenght *)
let encoded_len =
  Argon2.encoded_len ~t_cost ~m_cost ~parallelism ~salt_len ~hash_len
    ~kind:ID

let () = Mirage_crypto_rng_unix.use_default ()

(* generate salt for hash *)
let gen_salt len = Mirage_crypto_rng_unix.getrandom len

(* hash password *)
let hash_password passwd =
  Result.map Argon2.ID.encoded_to_string
    (Argon2.ID.hash_encoded ~t_cost ~m_cost ~parallelism ~hash_len
       ~encoded_len ~pwd:passwd ~salt:(gen_salt salt_len) )

(* verify password *)
let verify encoded_hash pwd =
  match Argon2.verify ~encoded:encoded_hash ~pwd ~kind:ID with
  | Ok true_or_false -> true_or_false
  | Error VERIFY_MISMATCH -> false
  | Error e -> raise (Failure (Argon2.ErrorCodes.message e))

let getAllUsers conn max user =
  let rec aux count =
    if count > max then Lwt.return []
    else
      Client.hgetall conn ("user:" ^ string_of_int count)
      >>= fun lst ->
      match List.assoc_opt "username" lst with
      | Some u when u = user -> Lwt.return lst
      | _ -> aux (count + 1)
  in
  aux 1

(*creates session based on user -> {user: user_id} *)
let sessions uid =
 fun request ->
  match Dream.session_field request "user" with
  | None ->
      Dream.invalidate_session request
      >>= fun _ ->
      Dream.set_session_field request "user" uid >>= fun _ -> Lwt.return_unit
  | Some _username -> Lwt.return_unit

let postAuthRegister request =
  Lwt.catch
    (fun () ->
      (* Helpers.checkPrems request (fun () -> *)
          Dream.body request
          >>= fun data ->
          let user = Openapi.usersPostRequest_of_json data in
          let rec aux conn (user : Openapi.usersPostRequest) =
            let created_at = Helpers.date in
            Client.unwatch conn
            >>= fun _ ->
            Client.watch conn ["user:id"]
            >>= fun _ ->
            Client.get conn "user:id"
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
              ["SET"; "user:id"; string_of_int next_id]
            >>= fun _ ->
            Client.send_custom_request conn
              [ "HSET"
              ; key
              ; "id"
              ; string_of_int next_id
              ; "username"
              ; user.username
              ; "password"
              ; Result.get_ok (hash_password user.password)
              ; "role"
              ; Openapi.json_of_usersPostRequestRole user.role
              ; "created_at"
              ; created_at ]
            >>= fun _ ->
            Client.exec conn
            >>= function
            | [] ->
                Dream.log "Error in postAuthRegister! Retrying..." ;
                aux conn user
            | [`Status "OK"; `Int n] when n >= 1 ->
                let user =
                  Openapi.create_user ~id:next_id ~username:user.username
                    ~role:
                      (Openapi.userRole_of_json
                         (Openapi.json_of_usersPostRequestRole user.role) )
                    ~created_at ()
                in
                Dream.json ~code:200
                  ~headers:[("Content-Type", "application/json")]
                  (Openapi.json_of_user user)
            | _ ->
                let error =
                  Openapi.create_authLoginPostResponse41 ~error:"Erro" ()
                in
                Dream.json ~code:500
                  ~headers:[("Content-Type", "application/json")]
                  (Openapi.json_of_authLoginPostResponse41 error)
          in
          Lwt_pool.use Db.pool (fun conn ->
              Client.get conn "user:id"
              >>= function
              | None -> aux conn user
              | Some id -> (
                  getAllUsers conn (int_of_string id) user.username
                  >>= function
                  | [] -> aux conn user
                  | _ ->
                      let error =
                        Openapi.create_authLoginPostResponse41
                          ~error:"already exits" ()
                      in
                      Dream.json ~code:400
                        ~headers:[("Content-Type", "application/json")]
                        (Openapi.json_of_authLoginPostResponse41 error) ) ) ) 
    (fun exn ->
      let error =
        Openapi.create_authLoginPostResponse41
          ~error:(Printexc.to_string exn) ()
      in
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Openapi.json_of_authLoginPostResponse41 error) )

let postAuthLogin request =
  Lwt.catch
    (fun () ->
      Dream.body request
      >>= fun data ->
      let user_req = Openapi.authLoginPostRequest_of_json data in
      Lwt_pool.use Db.pool (fun conn ->
          Client.get conn "user:id"
          >>= function
          | None -> Lwt.return []
          | Some id -> getAllUsers conn (int_of_string id) user_req.username )
      >>= function
      | [] ->
          let error =
            Openapi.create_authLoginPostResponse41
              ~error:"Invalid username or password" ()
          in
          Dream.json ~code:401
            ~headers:[("Content-Type", "application/json")]
            (Openapi.json_of_authLoginPostResponse41 error)
      | lst -> (
        match List.assoc_opt "password" lst with
        | Some pass when verify pass user_req.password ->
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
        | _ ->
            let error =
              Openapi.create_authLoginPostResponse41
                ~error:"Invalid username or password" ()
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
