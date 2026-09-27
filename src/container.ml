(** Funções para manipulação de containers Docker utilizando docker-api.

Este módulo fornece funções para criar, iniciar, parar e remover containers Docker, bem como para ler a saída deles. 

*)

exception Read_timeout

(** Lê o output de um stream Docker com limite de tempo.
    Devolve lista vazia se o timeout for atingido ou houver um erro interno.
    @param timeout limite em segundos *)
let read_all_timeout ~timeout st =
  let mutex = Mutex.create () in
  let result = ref None in
  let worker () =
    let value = try Ok (Docker.Stream.read_all st) with exn -> Error exn in
    Mutex.lock mutex ;
    result := Some value ;
    Mutex.unlock mutex
  in
  ignore (Thread.create worker ()) ;
  let deadline = Unix.gettimeofday () +. timeout in
  let rec wait_for_result () =
    Mutex.lock mutex ;
    match !result with
    | Some (Ok value) -> Mutex.unlock mutex ; value
    | Some (Error exn) -> Mutex.unlock mutex ; raise exn
    | None ->
        let remaining = deadline -. Unix.gettimeofday () in
        if remaining <= 0.0 then (Mutex.unlock mutex ; raise Read_timeout) ;
        Mutex.unlock mutex ;
        (* Poll frequently enough to avoid a one-second delay. *)
        Thread.delay (min remaining 0.5) ;
        wait_for_result ()
  in
  wait_for_result ()

(** Decodifica a saída de um container Docker.
    @param data dados brutos da saída
    @return par com a saída padrão e a saída de erro *)
let decode_docker_output (chunks : string list) : string * string =
  let read_uint32_be data pos =
    (Char.code data.[pos] lsl 24)
    lor (Char.code data.[pos + 1] lsl 16)
    lor (Char.code data.[pos + 2] lsl 8)
    lor Char.code data.[pos + 3]
  in
  let decode_frame data stdout stderr =
    let total = String.length data in
    let rec loop pos =
      if pos = total then ()
      else if total - pos < 8 then
        invalid_arg "Incomplete Docker frame header"
      else
        let stream = Char.code data.[pos] in
        let len = read_uint32_be data (pos + 4) in
        if total - pos < 8 + len then
          invalid_arg "Incomplete Docker frame payload" ;
        let payload = String.sub data (pos + 8) len in
        begin match stream with
        | 1 -> Buffer.add_string stdout payload
        | 2 -> Buffer.add_string stderr payload
        | _ -> ()
        end ;
        loop (pos + 8 + len)
    in
    loop 0
  in
  let stdout = Buffer.create 128 in
  let stderr = Buffer.create 128 in
  List.iter (fun chunk -> decode_frame chunk stdout stderr) chunks ;
  (Buffer.contents stdout, Buffer.contents stderr)
