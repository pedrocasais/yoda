open Lwt.Infix
open Redis_lwt

let json_headers = [("Content-Type", "application/json")]

let error_json ~code msg =
  let err = Openapi.create_authLoginPostResponse41 ~error:msg () in
  Dream.json ~code ~headers:json_headers
    (Openapi.json_of_authLoginPostResponse41 err)

let get_actor conn request =
  match Dream.session_field request "user" with
  | None -> Lwt.return "unknown"
  | Some uid ->
      Client.hget conn ("user:" ^ uid) "username"
      >|= function Some name -> name | None -> "user:" ^ uid

let read_config conn =
  Client.get conn Config.config_key
  >>= function
  | None -> Lwt.return_none
  | Some cfg ->
      Client.get conn Config.version_key
      >>= fun version_raw ->
      Client.get conn Config.updated_at_key
      >>= fun updated_at ->
      Client.get conn Config.updated_by_key
      >|= fun updated_by ->
      let version =
        match version_raw with Some x -> int_of_string x | None -> 0
      in
      Some
        ( cfg
        , version
        , Option.value updated_at ~default:""
        , Option.value updated_by ~default:"" )

let getAdminYodacConfig request =
  Lwt.catch
    (fun () ->
      Helpers.checkPrems request (fun () ->
          Lwt_pool.use Db.pool (fun conn ->
              read_config conn
              >>= function
              | None -> error_json ~code:404 "YodaC config not initialized"
              | Some (cfg, version, updated_at, updated_by) ->
                  Dream.json ~code:200 ~headers:json_headers
                    (Config.make_get_response_json
                      ~config_json:cfg ~version ~updated_at ~updated_by ) ) ) )
    (fun exn -> error_json ~code:500 (Printexc.to_string exn))

let putAdminYodacConfig request =
  Lwt.catch
    (fun () ->
      Helpers.checkPrems request (fun () ->
          Dream.body request
          >>= fun body ->
          let payload = Openapi.yodacConfigPutRequest_of_json body in
          match Config.validate_languages_config payload.config with
          | Error msg -> error_json ~code:400 msg
          | Ok () ->
              let new_cfg_json =
                Config.config_json_of_languages payload.config
              in
              Lwt_pool.use Db.pool (fun conn ->
                  get_actor conn request
                  >>= fun actor ->
                  let rec attempt retries =
                    Client.unwatch conn
                    >>= fun _ ->
                    Client.watch conn [Config.version_key]
                    >>= fun _ ->
                    Client.get conn Config.version_key
                    >>= fun current_version_raw ->
                    Client.get conn Config.config_key
                    >>= fun previous_cfg_raw ->
                    let current_version =
                      match current_version_raw with
                      | Some x -> int_of_string x
                      | None -> 0
                    in
                    let next_version = current_version + 1 in
                    let ts = Helpers.date () in
                    let history_json =
                      Config.make_history_entry_json
                        ~version:next_version ~timestamp:ts
                        ~changed_by:actor ~action:"update"
                        ~previous_config_json:previous_cfg_raw
                        ~new_config:payload.config
                    in
                    Client.multi conn
                    >>= fun _ ->
                    Client.send_custom_request conn
                      ["SET"; Config.config_key; new_cfg_json]
                    >>= fun _ ->
                    Client.send_custom_request conn
                      ["SET"; Config.version_key; string_of_int next_version]
                    >>= fun _ ->
                    Client.send_custom_request conn ["SET"; Config.updated_at_key; ts]
                    >>= fun _ ->
                    Client.send_custom_request conn ["SET"; Config.updated_by_key; actor]
                    >>= fun _ ->
                    Client.send_custom_request conn
                      ["RPUSH"; Config.history_key; history_json]
                    >>= fun _ ->
                    Client.exec conn
                    >>= function
                    | [] ->
                        if retries >= 5 then
                          error_json ~code:500 "Max retries exceeded"
                        else attempt (retries + 1)
                    | _ ->
                        Dream.json ~code:200 ~headers:json_headers
                          (Config.make_get_response_json
                            ~config_json:new_cfg_json ~version:next_version
                            ~updated_at:ts ~updated_by:actor )
                  in
                  attempt 0 ) ) )
    (fun exn -> error_json ~code:500 (Printexc.to_string exn))

let getAdminYodacConfigHistory request =
  Lwt.catch
    (fun () ->
      Helpers.checkPrems request (fun () ->
          Lwt_pool.use Db.pool (fun conn ->
              Client.lrange conn Config.history_key 0 (-1)
              >>= fun rows ->
              let rec collect acc = function
                | [] -> List.rev acc
                | x :: tl -> collect (x :: acc) tl
              in
              Dream.json ~code:200 ~headers:json_headers
                (Config.make_history_response_json
                   (collect [] rows) ) ) ) )
    (fun exn -> error_json ~code:500 (Printexc.to_string exn))
