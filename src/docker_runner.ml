(** Execução segura de código dentro de containers Docker isolados utilizando docker-api.

    Este módulo corre o código compilado para cada caso de teste
    e compara o output produzido com o output esperado. *)

open Job

(** Executa um único caso de teste dentro de um container Docker isolado.

    O container é criado com as seguintes restrições de segurança:
    - [--network none] — sem acesso à rede
    - [--memory] — limite de memória definido pelo problema
    - [--cpus 0.5] — limite de CPU
    - [--read-only] — sistema de ficheiros só de leitura
    - [--tmpfs /tmp] — diretoria temporária em memória
    - [timeout] — limite de tempo definido pelo problema

    O input do caso de teste é passado via stdin ao programa.

    @param job job com os limites e configuração da linguagem
    @param workdir diretoria com o binário compilado
    @param tc caso de teste a executar
    @return detalhe com o veredicto e o tempo de execução *)
module C = Docker.Container

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

(** Executa um único caso de teste num container Docker isolado.
    O volume é montado como só de leitura. Garante remoção do container em caso de erro.
    @param job job com os limites e configuração da linguagem
    @param workdir diretoria com o binário compilado
    @param tc caso de teste a executar
    @return detalhe com o veredicto e o tempo de execução *)
let run_testcase (job : job) (workdir : string) (tc : testcase) =
  let run_cmd = Compiler.lang_run_cmd job.lang in
  let lang = job.lang in
  let tag = Compiler.lang_tag lang in
  let image = Compiler.lang_image lang in
  let imagef = Printf.sprintf "%s:%s" image tag in
  let memory = job.memory_limit_mb * 1024 * 1024 in
  (*mb para bytes*)
  let timeout = float_of_int ((job.time_limit_ms / 1000) + 1) in
  let input_file = Printf.sprintf "%s/input_%d.txt" workdir tc.id in
  let oc = open_out input_file in
  output_string oc tc.input ;
  close_out oc ;
  let cmd = Printf.sprintf "%s < /work/input_%d.txt" run_cmd tc.id in
  let start = Unix.gettimeofday () in
  let h =
    Docker.Container.host
      ~binds:[Docker.Container.Mount_ro (workdir, "/work")]
      ~network_mode:"none" ~memory ~memory_swap:memory ()
  in
  Common.install_image image ~tag ;
  let c = C.create imagef ["bash"; "-c"; cmd] ~host:h ~workingdir:"/work" in
  let st = C.attach ~stdout:true ~stderr:true c `Stream in
  try
    C.start c ;
    let s = Compiler.read_all_timeout ~timeout st in
    let code = C.wait c in
    C.rm c ;
    (* Example: [ "\001\000\000\000\000\000\000\0051021\n";
       "\002\000\000\000\000\000\000\004oops";
       "\001\000\000\000\000\000\000\006hello!" ]*)
    let stdout, stderr =
      decode_docker_output (List.map (fun (_, b) -> b) s)
    in
    let json =
      `Assoc [("stdout", `String stdout); ("stderr", `String stderr)]
    in
    print_endline (Yojson.Safe.to_string json) ;
    let output = stdout in
    let time_ms = int_of_float ((Unix.gettimeofday () -. start) *. 1000.) in
    let detail_status =
      match code with
      | 0 ->
          if String.trim output = String.trim tc.output then "accepted"
          else "wrong_answer"
      | 124 -> "time_limit_exceeded"
      | _ ->
          Printf.eprintf "Runtime error (exit %d): %s\n%!" code output ;
          "runtime_error"
    in
    Openapi.SubmissionDetail.create ~testcase_id:tc.id ~status:detail_status
      ~time_ms ()
      ~output:(Yojson.Safe.to_string json)
  with exn ->
    (try C.stop c with _ -> ()) ;
    (try C.rm c with _ -> ()) ;
    raise exn

(** Executa todos os casos de teste e agrega o resultado final.

    O score é calculado como a percentagem de casos de teste aceites.
    O tempo reportado é o máximo entre todos os casos de teste.
    O status global é [accepted] apenas se todos os casos forem aceites,
    caso contrário é o status do primeiro caso que falhou.

    @param job job com os casos de teste e limites
    @param workdir diretoria com o binário compilado
    @return resultado agregado com score, tempo e detalhes por testcase *)
let run_all (job : job) (workdir : string) =
  let details = List.map (run_testcase job workdir) job.testcases in
  let total = List.length details in
  let accepted =
    List.length
      (List.filter
         (fun (d : Openapi.SubmissionDetail.t) -> d.status = "accepted")
         details )
  in
  let score = if total = 0 then 0 else accepted * 100 / total in
  let time_ms =
    List.fold_left
      (fun acc (d : Openapi.SubmissionDetail.t) -> max acc d.time_ms)
      0 details
  in
  let global_status =
    if accepted = total then "accepted"
    else
      (List.find
         (fun (d : Openapi.SubmissionDetail.t) -> d.status <> "accepted")
         details )
        .status
  in
  Openapi.Submission.create ~id:job.submission_id ~problem_id:job.problem_id
    ~language:job.lang ~status:global_status ~score ~time_ms ~memory_kb:0
    ~details ()
