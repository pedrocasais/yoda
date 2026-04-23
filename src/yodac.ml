let () =
  let default_host =
    if Sys.file_exists "/.dockerenv" then "valkey" else "127.0.0.1"
  in
  let host =
    Option.value (Sys.getenv_opt "VALKEY_HOST") ~default:default_host
  in
  let port =
    Option.value (Sys.getenv_opt "VALKEY_PORT") ~default:"6379"
    |> int_of_string
  in
  Worker.run ~host ~port ()
