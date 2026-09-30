open Lwt.Infix

let json_headers = [("Content-Type", "application/json")]

let getStats request =
  (fun () ->
    Lwt.catch
      (fun () ->
        Lwt_pool.use Db.pool (fun conn ->
            Stats.snapshot conn
            >>= fun (yodab, yodac) ->
            let payload =
              Openapi.AdminStatsResponse.create
                ~api_version:Build_info.api_version
                ~yoda_version:Build_info.yoda_version
                ~contributors:Build_info.contributors
                ~yodab:
                  (Openapi.AdminYodabStats.create
                     ~yodab_requests_total:yodab.yodab_requests_total
                     ~yodab_requests_per_minute:
                       yodab.yodab_requests_per_minute
                     ~submissions_total:yodab.submissions_total
                     ~submissions_per_minute:yodab.submissions_per_minute () )
                ~yodac:
                  (Openapi.AdminYodacStats.create
                     ~queued_jobs_total:yodac.queued_jobs_total
                     ~queued_jobs_per_minute:yodac.queued_jobs_per_minute
                     ~processed_jobs_total:yodac.processed_jobs_total
                     ~processed_jobs_per_minute:
                       yodac.processed_jobs_per_minute () )
                ()
            in
            Dream.json ~code:200 ~headers:json_headers
              (Openapi.AdminStatsResponse.to_json payload) ) )
      (fun exn ->
        let err =
          Openapi.ErrorResponse.create ~error:(Printexc.to_string exn) ()
        in
        Dream.json ~code:500 ~headers:json_headers
          (Openapi.ErrorResponse.to_json err) ) )
  |> Helpers.check_admin_permissions request
