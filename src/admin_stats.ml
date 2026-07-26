open Lwt.Infix

let json_headers = [("Content-Type", "application/json")]

let parse_api_version_from_openapi_info () =
  let openapi_path = "schemas/openapi.yaml" in
  if Sys.file_exists openapi_path then
    let ic = open_in openapi_path in
    let content =
      Fun.protect
        ~finally:(fun () -> close_in_noerr ic)
        (fun () -> really_input_string ic (in_channel_length ic))
    in
    let marker = "version:" in
    let lines = String.split_on_char '\n' content in
    let rec find = function
      | [] -> "1.0"
      | line :: tl ->
          let trimmed = String.trim line in
          if
            String.length trimmed >= String.length marker
            && String.sub trimmed 0 (String.length marker) = marker
          then
            let raw =
              String.sub trimmed (String.length marker)
                (String.length trimmed - String.length marker)
              |> String.trim
            in
            String.trim raw
            |> String.map (fun c -> if c = '"' then ' ' else c)
            |> String.trim
          else find tl
    in
    find lines
  else "1.0"

let run_cmd_capture cmd =
  try
    let ic = Unix.open_process_in cmd in
    let out = input_line ic |> String.trim in
    let _ = Unix.close_process_in ic in
    out
  with _ -> ""

let unique_sorted xs =
  xs |> List.filter (fun s -> s <> "") |> List.sort_uniq String.compare

let read_contributors_from_git () =
  let cmd = "git log --format='%aN'" in
  let ic = Unix.open_process_in cmd in
  let rec loop acc =
    match input_line ic with
    | line -> loop (String.trim line :: acc)
    | exception End_of_file -> List.rev acc
  in
  let names = try loop [] with _ -> [] in
  let _ = Unix.close_process_in ic in
  let sorted = unique_sorted names in
  if sorted = [] then ["unknown"] else sorted

let read_yoda_version_from_git () =
  let short = run_cmd_capture "git rev-parse --short HEAD" in
  if short = "" then "sha-unknown"
  else
    let dirty = run_cmd_capture "git status --porcelain" in
    if dirty = "" then "sha-" ^ short else "dirty-" ^ short

let getStats request =
  Lwt.catch
    (fun () ->
      Helpers.checkPrems request (fun () ->
          Lwt_pool.use Db.pool (fun conn ->
              Stats.snapshot conn
              >>= fun (yodab, yodac) ->
              let payload =
                `Assoc
                  [ ( "api_version"
                    , `String (parse_api_version_from_openapi_info ()) )
                  ; ("yoda_version", `String (read_yoda_version_from_git ()))
                  ; ( "contributors"
                    , `List
                        (List.map
                           (fun name -> `String name)
                           (read_contributors_from_git ()) ) )
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
        Openapi.create_authLoginPostResponse41
          ~error:(Printexc.to_string exn) ()
      in
      Dream.json ~code:500 ~headers:json_headers
        (Openapi.json_of_authLoginPostResponse41 err) )
