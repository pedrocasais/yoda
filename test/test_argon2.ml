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

let () =
  let hashed_pwd = Result.get_ok (hash_password "my insecure password") in
  Printf.printf "Hashed password: %s\n" hashed_pwd ;
  let fst_attempt = "my secure password" in
  Printf.printf "'%s' is correct? %B\n" fst_attempt
    (verify hashed_pwd fst_attempt) ;
  let snd_attempt = "my insecure password" in
  Printf.printf "'%s' is correct? %B\n" snd_attempt
    (verify hashed_pwd snd_attempt)
