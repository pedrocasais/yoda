(** Funções auxiliares

  Neste módulo estão definidas funções utilizadas por vários módulos. *)

open Lwt.Infix
open Redis_lwt

(** Tipo de acesso para verificar permissões de utilizador. *)
type access = Bad_Request | Unauthorized | Forbidden | Ok

let get_actor_id request =
  match Dream.session_field request "user" with
  | Some id -> id
  | None -> failwith "No user id found in session! Dangerous operation."

let get_actor_role conn actor_id =
  Client.hget conn ("user:" ^ actor_id) "role"

let get_actor_groups conn actor_id =
  Client.hget conn ("user:" ^ actor_id) "groups"
  >>= fun user ->
  Lwt.return (Option.value ~default:"[]" user |> Openapi.UserGroups.of_json)

(** [check_admin_permissions request next] verifica se o user tem autorização de Admin para aceder a [request]. *)
let check_admin_permissions request next =
  let id_session = Dream.session_field request "user" in
  (* obtém role de um dado user:id_session. *)
  let aux = function
    | None -> Lwt.return Unauthorized
    | Some id -> (
        Lwt_pool.use Db.pool (fun conn -> get_actor_role conn id)
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

(* [TODO] replace by Date.now_utc *)

(** [date] obtém a data atual no formato year-month-day-hour-min-sec. *)
let date () =
  let today : Unix.tm = Unix.localtime (Unix.time ()) in
  let pp_tm ppf t =
    Format.fprintf ppf "%4d-%02d-%02dT%02d:%02d:%02dZ"
      (t.Unix.tm_year + 1900) (t.Unix.tm_mon + 1) t.Unix.tm_mday
      t.Unix.tm_hour t.Unix.tm_min t.Unix.tm_sec
  in
  Format.asprintf "%a" pp_tm today

module Date = struct
  let is_leap_year y = (y mod 4 = 0 && y mod 100 <> 0) || y mod 400 = 0

  let days_in_month y m =
    match m with
    | 1 | 3 | 5 | 7 | 8 | 10 | 12 -> 31
    | 4 | 6 | 9 | 11 -> 30
    | 2 -> if is_leap_year y then 29 else 28
    | _ -> 0

  let is_valid_utc_datetime date_time =
    let int_sub s start len =
      try Some (int_of_string (String.sub s start len)) with _ -> None
    in
    let expected_format =
      String.length date_time = 20
      && date_time.[4] = '-'
      && date_time.[7] = '-'
      && date_time.[10] = 'T'
      && date_time.[13] = ':'
      && date_time.[16] = ':'
      && date_time.[19] = 'Z'
    in
    if not expected_format then false
    else
      match
        ( int_sub date_time 0 4
        , int_sub date_time 5 2
        , int_sub date_time 8 2
        , int_sub date_time 11 2
        , int_sub date_time 14 2
        , int_sub date_time 17 2 )
      with
      | Some year, Some month, Some day, Some hour, Some minute, Some second
        ->
          month >= 1 && month <= 12 && day >= 1
          && day <= days_in_month year month
          && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59
          && second >= 0 && second <= 59
      | _ -> false

  let now_utc () =
    let now : Unix.tm = Unix.gmtime (Unix.time ()) in
    Format.asprintf "%04d-%02d-%02dT%02d:%02d:%02dZ"
      (now.Unix.tm_year + 1900) (now.Unix.tm_mon + 1) now.Unix.tm_mday
      now.Unix.tm_hour now.Unix.tm_min now.Unix.tm_sec

  let has_passed_utc_datetime date_time =
    is_valid_utc_datetime date_time
    && String.compare date_time (now_utc ()) <= 0
end

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
   @param user_id ID do utilizador
   @param user_role Função do utilizador
   @param lst lista de detalhes de submissão
   @return devolve uma lista de tipo [Openapi.submissionDetails list] para ser usada na criação de [[Openapi.submission list]]
   *)
let makeSubmissionDetailsList user_id user_role l =
  Openapi.SubmissionDetails.of_json (List.assoc "details" l)
  |> List.map (fun (sd : Openapi.SubmissionDetail.t) ->
      Openapi.create_submissionDetail ~testcase_id:sd.testcase_id
        ~status:sd.status ~time_ms:sd.time_ms
        ?output:
          ( if
              Openapi.userRole_of_json user_role = Openapi.Admin
              || Openapi.userRole_of_json user_role = Openapi.Judge
              || Openapi.userRole_of_json user_role = Openapi.User
                 && user_id = List.assoc "user_id" l
            then
              Some
                (Option.value
                   ~default:
                     (Openapi.SubmissionDetailOutput.create ~stdout:""
                        ~stderr:"" ~return_code:(-1) () )
                   sd.output )
            else None )
        () )

(** [makeSubmission user_id user_role lst] cria uma submissão com os dados fornecidos.
    @param user_id ID do utilizador
    @param user_role Função do utilizador
    @param lst Lista de dados da submissão
    @return Devolve uma submissão de tipo [Openapi.submission] *)
let makeSubmission user_id user_role lst =
  let user_role =
    Option.value ~default:(Openapi.UserRole.to_json Openapi.User) user_role
  in
  Openapi.create_submission
    ~id:(int_of_string (List.assoc "id" lst))
    ~problem_id:(int_of_string (List.assoc "problem_id" lst))
    ~language:(List.assoc "language" lst)
    ~status:(List.assoc "status" lst)
    ~score:(int_of_string (List.assoc "score" lst))
    ~time_ms:(int_of_string (List.assoc "time_ms" lst))
    ~memory_kb:(int_of_string (List.assoc "memory_kb" lst))
    ~details:(makeSubmissionDetailsList user_id user_role lst)
    ~owner:(user_id = List.assoc "user_id" lst)
    ?owner_id:
      ( if
          Openapi.userRole_of_json user_role = Openapi.Admin
          || Openapi.userRole_of_json user_role = Openapi.Judge
        then Some (int_of_string (List.assoc "user_id" lst))
        else None )
    ?created_at:
      ( if
          Openapi.userRole_of_json user_role = Openapi.Admin
          || Openapi.userRole_of_json user_role = Openapi.Judge
        then try Some (List.assoc "created_at" lst) with Not_found -> None
        else None )
    ()

let error_msg msg =
  let error = Openapi.ErrorResponse.create ~error:msg () in
  Openapi.ErrorResponse.to_json error
