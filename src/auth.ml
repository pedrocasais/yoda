(** Módulo de Autenticação

    Este módulo contém funções para criar utilizadores e fazer a sua autenticação. *)

open Lwt.Infix
open Redis_lwt

(** {2 Variáveis de controlo para o Argon2}

    Estes parâmetros controlam a força e performance do algoritmo de hash de passwords.
*)

(** [t_cost] é o tempo de computação da hash dado em número de iterações *)
let t_cost = 2

(** [m_cost] é a memória total usada para a hash, em kibibytes*)
and m_cost = 65536

(** [parallelism] é o número de threads em paralelo usadas para a hash *)
and parallelism = 1

(** [hash_len] é o tamanho final da hash gerada em bytes *)
and hash_len = 32

(** [salt_len] é o tamanho do salt usado na hash em bytes *)
and salt_len = 32

(** [encoded_len] cálcula o tamanho da hash codificada *)
let encoded_len =
  Argon2.encoded_len ~t_cost ~m_cost ~parallelism ~salt_len ~hash_len
    ~kind:ID

(** inicializa o Mirage Crypto *)
let () = Mirage_crypto_rng_unix.use_default ()

(** [gen_salt len] gera uma string de tamanho [len] com random bytes *)
let gen_salt len = Mirage_crypto_rng_unix.getrandom len

(** [hash_password passwd]Cria um hash Argon2id para a password fornecida [passwd].
    @return tuplo com o resultado contendo a hash codificada ou um erro. *)
let hash_password passwd =
  Result.map Argon2.ID.encoded_to_string
    (Argon2.ID.hash_encoded ~t_cost ~m_cost ~parallelism ~hash_len
       ~encoded_len ~pwd:passwd ~salt:(gen_salt salt_len) )

(** [verify encoded_hash pwd] Verifica se a password,[pwd], corresponde à hash codificada,[encoded_hash].
    @return [true] se válida, [false] caso contrário. *)
let verify encoded_hash pwd =
  match Argon2.verify ~encoded:encoded_hash ~pwd ~kind:ID with
  | Ok true_or_false -> true_or_false
  | Error VERIFY_MISMATCH -> false
  | Error e -> raise (Failure (Argon2.ErrorCodes.message e))

(** [getAllUsers conn max user] verifica se [user] existe na [Db]
  @param conn conexão com a base de dados
  @param max user_id máximo a procurar 
  @param user username a verificar
  @return devolve [(string*string)list Lwt.t] se existir com as informações do utilizador,
   [[] Lwt.t] caso não exista.
*)
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

(** [sessions uid] invalida a sessão atual e criar uma nova para o utilizador com id [uid].
  @param uid id de utilizador  *)
let sessions uid =
 fun request ->
  Dream.invalidate_session request
  >>= fun () -> Dream.set_session_field request "user" uid

(** [postAuthRegister request] Rota para registar um novo utilizador.
    Apenas administradores podem criar novos utilizadores. 
    @return devolve o user criado, caso contrário erro *)
let postAuthRegister request =
  Lwt.catch
    (fun () ->
      (** [Helpers.checkPrems request] verifica se o utilizador tem permissões de administrador *)
      Helpers.checkPrems request (fun () ->
          Dream.body request
          >>= fun data ->
          let user = Openapi.usersPostRequest_of_json data in
          let rec aux conn (user : Openapi.usersPostRequest) attempt passwd =
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
              ; passwd
              ; "role"
              ; Openapi.json_of_usersPostRequestRole user.role
              ; "created_at"
              ; created_at ]
            >>= fun _ ->
            Client.exec conn
            >>= function
            | [] ->
                if attempt >= 5 then
                  let error =
                    Openapi.create_authLoginPostResponse41
                      ~error:"Max retries exceeded" ()
                  in
                  Dream.json ~code:500
                    ~headers:[("Content-Type", "application/json")]
                    (Openapi.json_of_authLoginPostResponse41 error)
                else
                  let base = 0.05 *. (2.0 *. float_of_int attempt) in
                  let diff = Random.float base in
                  Dream.log "Error in postAuthRegister! Retrying..." ;
                  Lwt_unix.sleep (base +. diff)
                  >>= fun () -> aux conn user (attempt + 1) passwd
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
              | None ->
                  aux conn user 0
                    (Result.get_ok (hash_password user.password))
              | Some id -> (
                  getAllUsers conn (int_of_string id) user.username
                  >>= function
                  | [] ->
                      aux conn user 0
                        (Result.get_ok (hash_password user.password))
                  | _ ->
                      let error =
                        Openapi.create_authLoginPostResponse41
                          ~error:"User already exists" ()
                      in
                      Dream.json ~code:400
                        ~headers:[("Content-Type", "application/json")]
                        (Openapi.json_of_authLoginPostResponse41 error) ) ) ) )
    (fun exn ->
      let error =
        Openapi.create_authLoginPostResponse41
          ~error:(Printexc.to_string exn) ()
      in
      Dream.json ~code:500
        ~headers:[("Content-Type", "application/json")]
        (Openapi.json_of_authLoginPostResponse41 error) )

(** [postAuthLogin request] Rota para efetuar o Login de um user.
  @return Caso bem sucedido devolve um [token] de sessão e o [user], caso contrário erro. *)
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
