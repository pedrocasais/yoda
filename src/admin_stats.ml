open Lwt.Infix

let json_headers = [("Content-Type", "application/json")]

let getStats request =
  Lwt.catch
    (fun () ->
      Helpers.checkPrems request (fun () ->
          Lwt_pool.use Db.pool (fun conn ->
              Stats.snapshot conn
              >>= fun (yodab, yodac) ->
              let payload =
                `Assoc
                  [ ("api_version", `String Build_info.api_version)
                  ; ("yoda_version", `String Build_info.yoda_version)
                  ; ( "contributors"
                    , `List
                        (List.map
                           (fun name -> `String name)
                           Build_info.contributors ) )
                  ; ( "yodab"
                    , `Assoc
                        [ ( "yodab_requests_total"
                          , `Int yodab.yodab_requests_total )
                        ; ( "yodab_requests_per_minute"
                          , `Int yodab.yodab_requests_per_minute )
                        ; ("submissions_total", `Int yodab.submissions_total)
                        ; ( "submissions_per_minute"
                          , `Int yodab.submissions_per_minute ) ] )
                  ; ( "yodac"
                    , `Assoc
                        [ ("queued_jobs", `Int yodac.queued_jobs)
                        ; ( "queued_jobs_per_minute"
                          , `Int yodac.queued_jobs_per_minute )
                        ; ( "processed_jobs_total"
                          , `Int yodac.processed_jobs_total )
                        ; ( "processed_jobs_per_minute"
                          , `Int yodac.processed_jobs_per_minute ) ] ) ]
              in
              Dream.json ~code:200 ~headers:json_headers
                (Yojson.Safe.to_string payload) ) ) )
    (fun exn ->
      let err =
        Openapi.ErrorResponse.create ~error:(Printexc.to_string exn) ()
      in
      Dream.json ~code:500 ~headers:json_headers
        (Openapi.ErrorResponse.to_json err) )
