open Lwt.Infix
open Redis_lwt

type yodab_snapshot =
  { yodab_requests_total: int
  ; yodab_requests_per_minute: int
  ; submissions_total: int
  ; submissions_per_minute: int }

type yodac_snapshot =
  { queued_jobs: int
  ; queued_jobs_per_minute: int
  ; processed_jobs_total: int
  ; processed_jobs_per_minute: int }

let key_yodab_requests_total = "stats:yodab:requests:total"

let key_submissions_total = "stats:yodab:submissions:total"

let key_processed_jobs_total = "stats:yodac:processed_jobs:total"

let key_prefix_yodab_requests_minute = "stats:yodab:requests:per_minute"

let key_prefix_submissions_minute = "stats:yodab:submissions:per_minute"

let key_prefix_queued_jobs_minute = "stats:yodac:queued_jobs:per_minute"

let key_prefix_processed_jobs_minute =
  "stats:yodac:processed_jobs:per_minute"

let key_submission_queue = "submission:job"

let current_minute_bucket () = int_of_float (Unix.time () /. 60.)

let minute_key prefix =
  Printf.sprintf "%s:%d" prefix (current_minute_bucket ())

let incr_key conn key =
  Client.send_custom_request conn ["INCR"; key] >|= fun _ -> ()

let get_int_key conn key =
  Client.get conn key
  >|= function Some v -> ( try int_of_string v with _ -> 0 ) | None -> 0

let get_list_len conn key =
  Client.send_custom_request conn ["LLEN"; key]
  >|= function `Int n -> n | _ -> 0

let record_yodab_request () =
  Lwt_pool.use Db.pool (fun conn ->
      incr_key conn key_yodab_requests_total
      >>= fun () ->
      incr_key conn (minute_key key_prefix_yodab_requests_minute) )

let record_submission_created () =
  Lwt_pool.use Db.pool (fun conn ->
      incr_key conn key_submissions_total
      >>= fun () ->
      incr_key conn (minute_key key_prefix_submissions_minute)
      >>= fun () -> incr_key conn (minute_key key_prefix_queued_jobs_minute) )

let record_processed_job () =
  Lwt_pool.use Db.pool (fun conn ->
      incr_key conn key_processed_jobs_total
      >>= fun () ->
      incr_key conn (minute_key key_prefix_processed_jobs_minute) )

let snapshot conn =
  get_int_key conn key_yodab_requests_total
  >>= fun yodab_requests_total ->
  get_int_key conn (minute_key key_prefix_yodab_requests_minute)
  >>= fun yodab_requests_per_minute ->
  get_int_key conn key_submissions_total
  >>= fun submissions_total ->
  get_int_key conn (minute_key key_prefix_submissions_minute)
  >>= fun submissions_per_minute ->
  get_list_len conn key_submission_queue
  >>= fun queued_jobs ->
  get_int_key conn (minute_key key_prefix_queued_jobs_minute)
  >>= fun queued_jobs_per_minute ->
  get_int_key conn key_processed_jobs_total
  >>= fun processed_jobs_total ->
  get_int_key conn (minute_key key_prefix_processed_jobs_minute)
  >|= fun processed_jobs_per_minute ->
  ( { yodab_requests_total
    ; yodab_requests_per_minute
    ; submissions_total
    ; submissions_per_minute }
  , { queued_jobs
    ; queued_jobs_per_minute
    ; processed_jobs_total
    ; processed_jobs_per_minute } )
