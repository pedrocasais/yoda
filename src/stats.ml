open Lwt.Infix
open Redis_lwt

type yodab_snapshot =
  { yodab_requests_total: int
  ; yodab_requests_per_minute: int
  ; submissions_total: int
  ; submissions_per_minute: int }

type yodac_snapshot =
  { queued_jobs_total: int
  ; queued_jobs_per_minute: int
  ; processed_jobs_total: int
  ; processed_jobs_per_minute: int }

type snapshot = yodab_snapshot * yodac_snapshot

let key_yodab_requests_total = "stats:yodab:requests:total"

let key_submissions_total = "stats:yodab:submissions:total"

let key_processed_jobs_total = "stats:yodac:processed_jobs:total"

let key_submission_queue = "submission:job"

let prefix_yodab_requests_minute = "stats:yodab:requests:per_minute"

let prefix_submissions_minute = "stats:yodab:submissions:per_minute"

let prefix_queued_jobs_minute = "stats:yodac:queued_jobs:per_minute"

let prefix_processed_jobs_minute = "stats:yodac:processed_jobs:per_minute"

let current_minute () = int_of_float (Unix.gettimeofday () /. 60.)

let minute_key prefix = Printf.sprintf "%s:%d" prefix (current_minute ())

let incr_persistent conn keys =
  let script =
    "for i, key in ipairs(KEYS) do " ^ "redis.call('INCR', key) "
    ^ "end return 1"
  in
  Client.send_custom_request conn
    (["EVAL"; script; string_of_int (List.length keys)] @ keys)
  >|= fun _ -> ()

let incr_minute conn key =
  let script =
    "redis.call('INCR', KEYS[1]) " ^ "redis.call('EXPIRE', KEYS[1], 120) "
    ^ "return 1"
  in
  Client.send_custom_request conn ["EVAL"; script; "1"; key] >|= fun _ -> ()

let get_int = function None -> 0 | Some value -> int_of_string value

let get_string conn key = Client.get conn key

let get_list_length conn key =
  Client.send_custom_request conn ["LLEN"; key]
  >|= function `Int length -> length | _ -> 0

let record_yodab_request () =
  Lwt_pool.use Db.pool (fun conn ->
      incr_persistent conn [key_yodab_requests_total]
      >>= fun () ->
      incr_minute conn (minute_key prefix_yodab_requests_minute) )

let record_submission_created () =
  Lwt_pool.use Db.pool (fun conn ->
      incr_persistent conn [key_submissions_total]
      >>= fun () ->
      incr_minute conn (minute_key prefix_submissions_minute)
      >>= fun () -> incr_minute conn (minute_key prefix_queued_jobs_minute) )

let record_processed_job () =
  Lwt_pool.use Db.pool (fun conn ->
      incr_persistent conn [key_processed_jobs_total]
      >>= fun () ->
      incr_minute conn (minute_key prefix_processed_jobs_minute) )

let snapshot conn =
  let requests_minute = minute_key prefix_yodab_requests_minute in
  let submissions_minute = minute_key prefix_submissions_minute in
  let queued_jobs_minute = minute_key prefix_queued_jobs_minute in
  let processed_jobs_minute = minute_key prefix_processed_jobs_minute in
  get_string conn key_yodab_requests_total
  >>= fun requests_total ->
  get_string conn requests_minute
  >>= fun requests_per_minute ->
  get_string conn key_submissions_total
  >>= fun submissions_total ->
  get_string conn submissions_minute
  >>= fun submissions_per_minute ->
  get_list_length conn key_submission_queue
  >>= fun queued_jobs_total ->
  get_string conn queued_jobs_minute
  >>= fun queued_jobs_per_minute ->
  get_string conn key_processed_jobs_total
  >>= fun processed_jobs_total ->
  get_string conn processed_jobs_minute
  >|= fun processed_jobs_per_minute ->
  ( { yodab_requests_total= get_int requests_total
    ; yodab_requests_per_minute= get_int requests_per_minute
    ; submissions_total= get_int submissions_total
    ; submissions_per_minute= get_int submissions_per_minute }
  , { queued_jobs_total
    ; queued_jobs_per_minute= get_int queued_jobs_per_minute
    ; processed_jobs_total= get_int processed_jobs_total
    ; processed_jobs_per_minute= get_int processed_jobs_per_minute } )
