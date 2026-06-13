open Lwt.Infix
open Redis_lwt

(** {1 Módulo de Funções auxiliares } 
    Neste módulo estão definidas funções utilizadas por vários módulos*)

(** Tipo de acesso para verificar permissões de user*)
type access = Bad_Request | Unauthorized | Forbidden | Ok

(** [checkPrems request next] verifica se o user tem autorização de Admin para aceder a [request] *)
let checkPrems request next =
  let id_session = Dream.session_field request "user" in
  (* obtém role de um dado user:id_session *)
  let aux = function
    | None -> Lwt.return Unauthorized
    | Some id -> (
        Lwt_pool.use Db.pool (fun conn ->
            Client.hget conn ("user:" ^ id) "role" )
        >>= function
        | Some role ->
            if Openapi.userRole_of_json role = Openapi.Admin then
              Lwt.return Ok
            else Lwt.return Forbidden
        | None -> Lwt.return Bad_Request )
  in
  aux id_session
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
        Openapi.create_authLoginPostResponse41 ~error:"Unauthorized access"
          ()
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
  | Ok -> next ()

(** [date] get date from today in format year-month-day-hour-min-sec *)
let date =
  let today : Unix.tm = Unix.localtime (Unix.time ()) in
  let pp_tm ppf t =
    Format.fprintf ppf "%4d-%02d-%02dT%02d:%02d:%02dZ"
      (t.Unix.tm_year + 1900) (t.Unix.tm_mon + 1) t.Unix.tm_mday
      t.Unix.tm_hour t.Unix.tm_min t.Unix.tm_sec
  in
  Format.asprintf "%a" pp_tm today

(** [getAllTestCases conn lst] get all testcases from db 
 - conn: conexão [Db]
 - lst: list of testcase to get  *)
let getAllTestCases conn lst =
  let rec aux acc = function
    | [] -> Lwt.return acc
    | hd :: tl -> (
        Client.hgetall conn ("testcase:" ^ hd)
        >>= function
        | [] ->
            Lwt.fail_with
              (Printf.sprintf
                 "Some testCases maybe be missing. Please check if \
                  testcase:%s is defined in a HASH"
                 hd )
        | x -> aux (List.rev_append [x] acc) tl )
  in
  aux [] lst

(** [makeSubmissionDetailsList lst] make list of submission details convert from string to yojson to
   Openapi.submission list
   - lst: list of details to add to final list 
   *)
let makeSubmissionDetailsList lst =
  Yojson.Basic.Util.to_list (Yojson.Basic.from_string lst)
  |> List.map (fun x ->
      let lst = Yojson.Basic.Util.to_assoc x in
      Openapi.create_submissionDetails
        ~testcase_id:
          (Yojson.Basic.Util.to_int (List.assoc "testcase_id" lst))
        ~status:(Yojson.Basic.Util.to_string (List.assoc "status" lst))
        ~time_ms:(Yojson.Basic.Util.to_int (List.assoc "time_ms" lst))
        () )
