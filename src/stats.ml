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

let key_yodab_requests_minute = "stats:yodab:requests:per_minute"

let key_submissions_minute = "stats:yodab:submissions:per_minute"

let key_queued_jobs_minute = "stats:yodac:queued_jobs:per_minute"

let key_processed_jobs_minute = "stats:yodac:processed_jobs:per_minute"

let incr_keys conn keys =
  let script =
    "for i, key in ipairs(KEYS) do " ^ "redis.call('INCR', key) "
    ^ "redis.call('EXPIRE', key, 60) " ^ "end return 1"
  in
  Client.send_custom_request conn
    (["EVAL"; script; string_of_int (List.length keys)] @ keys)
  >|= fun _ -> ()

let get_int = function None -> 0 | Some value -> int_of_string value

let get_string conn key = Client.get conn key

let get_list_length conn key =
  Client.send_custom_request conn ["LLEN"; key]
  >|= function `Int length -> length | _ -> 0

let record_keys keys = Lwt_pool.use Db.pool (fun conn -> incr_keys conn keys)

let record_yodab_request () =
  record_keys [key_yodab_requests_total; key_yodab_requests_minute]

let record_submission_created () =
  record_keys
    [key_submissions_total; key_submissions_minute; key_queued_jobs_minute]

let record_processed_job () =
  record_keys [key_processed_jobs_total; key_processed_jobs_minute]

let snapshot conn =
  get_string conn key_yodab_requests_total
  >>= fun requests_total ->
  get_string conn key_yodab_requests_minute
  >>= fun requests_per_minute ->
  get_string conn key_submissions_total
  >>= fun submissions_total ->
  get_string conn key_submissions_minute
  >>= fun submissions_per_minute ->
  get_list_length conn key_submission_queue
  >>= fun queued_jobs_total ->
  get_string conn key_queued_jobs_minute
  >>= fun queued_jobs_per_minute ->
  get_string conn key_processed_jobs_total
  >>= fun processed_jobs_total ->
  get_string conn key_processed_jobs_minute
  >|= fun processed_jobs_per_minute ->
  ( { yodab_requests_total= get_int requests_total
    ; yodab_requests_per_minute= get_int requests_per_minute
    ; submissions_total= get_int submissions_total
    ; submissions_per_minute= get_int submissions_per_minute }
  , { queued_jobs_total
    ; queued_jobs_per_minute= get_int queued_jobs_per_minute
    ; processed_jobs_total= get_int processed_jobs_total
    ; processed_jobs_per_minute= get_int processed_jobs_per_minute } )
