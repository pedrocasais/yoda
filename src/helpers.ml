(** Funções auxiliares

  Neste módulo estão definidas funções utilizadas por vários módulos. *)

open Lwt.Infix
open Redis_lwt

(** Tipo de acesso para verificar permissões de utilizador. *)
type access = Bad_Request | Unauthorized | Forbidden | Ok

(** [checkPrems request next] verifica se o user tem autorização de Admin para aceder a [request]. *)
let checkPrems request next =
  let id_session = Dream.session_field request "user" in
  (* obtém role de um dado user:id_session. *)
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
      let error = Openapi.ErrorResponse.create ~error:"Bad Request" () in
      Dream.json ~code:400
        ~headers:[("Content-Type", "application/json")]
        (Openapi.ErrorResponse.to_json error)
  | Unauthorized ->
      let error =
        Openapi.ErrorResponse.create ~error:"Unauthorized access" ()
      in
      Dream.json ~code:401
        ~headers:[("Content-Type", "application/json")]
        (Openapi.ErrorResponse.to_json error)
  | Forbidden ->
      let error =
        Openapi.ErrorResponse.create ~error:"Forbidden - admin only" ()
      in
      Dream.json ~code:403
        ~headers:[("Content-Type", "application/json")]
        (Openapi.ErrorResponse.to_json error)
  | Ok -> next ()

(** [date] obtém a data atual no formato year-month-day-hour-min-sec. *)
let date () =
  let today : Unix.tm = Unix.localtime (Unix.time ()) in
  let pp_tm ppf t =
    Format.fprintf ppf "%4d-%02d-%02dT%02d:%02d:%02dZ"
      (t.Unix.tm_year + 1900) (t.Unix.tm_mon + 1) t.Unix.tm_mday
      t.Unix.tm_hour t.Unix.tm_min t.Unix.tm_sec
  in
  Format.asprintf "%a" pp_tm today

(** [getAllTestCases conn lst] obtém todos os casos de teste pedidos.
    @param conn conexão com a base de dados
    @param lst ids de testecases de um dado problema.
    @return devolve informaçãoes sobre testecases. *)
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

(** [makeSubmissionDetailsList lst] converte uma string numa lista yojson numa lista de detalhes de submissão, [Openapi.submissionDetails list]
   @param lst lista de detalhes de submissão
   @return devolve uma lista de tipo [Openapi.submissionDetails list] para ser usada na criação de [[Openapi.submission list]]
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

let get_actor_id request =
  match Dream.session_field request "user" with
  | Some id -> id
  | None -> failwith "No user id found in session"

let escape_json_string s =
  let b = Buffer.create (String.length s + 16) in
  String.iter
    (function
      | '"' -> Buffer.add_string b "\\\""
      | '\\' -> Buffer.add_string b "\\\\"
      | '\n' -> Buffer.add_string b "\\n"
      | '\r' -> Buffer.add_string b "\\r"
      | '\t' -> Buffer.add_string b "\\t"
      | c -> Buffer.add_char b c )
    s ;
  Buffer.contents b

let unscape_json_string s =
  let b = Buffer.create (String.length s) in
  let rec aux i =
    if i >= String.length s then ()
    else if s.[i] = '\\' && i + 1 < String.length s then (
      match s.[i + 1] with
      | '"' ->
          Buffer.add_char b '"' ;
          aux (i + 2)
      | '\\' ->
          Buffer.add_char b '\\' ;
          aux (i + 2)
      | 'n' ->
          Buffer.add_char b '\n' ;
          aux (i + 2)
      | 'r' ->
          Buffer.add_char b '\r' ;
          aux (i + 2)
      | 't' ->
          Buffer.add_char b '\t' ;
          aux (i + 2)
      | _ ->
          Buffer.add_char b s.[i] ;
          aux (i + 1) )
    else (
      Buffer.add_char b s.[i] ;
      aux (i + 1) )
  in
  aux 0 ; Buffer.contents b
