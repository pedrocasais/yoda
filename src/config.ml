open Lwt.Infix
open Redis_lwt

let config_key = "yodac:config:languages"

let version_key = "yodac:config:languages:version"

let updated_at_key = "yodac:config:languages:updated_at"

let updated_by_key = "yodac:config:languages:updated_by"

let history_key = "yodac:config:languages:history"

type lang_config_entry =
  { ext: string
  ; image: string
  ; tag: string
  ; compile: string option
  ; run: string }

(** Caminho para o ficheiro de configuração de linguagens.
    Pode ser configurado via variável de ambiente [YODAC_LANG_CONFIG].
    Por omissão: [languagesv2.yaml]. *)
let lang_config_path =
  Option.value (Sys.getenv_opt "YODAC_LANG_CONFIG") ~default:"languages.yaml"

let normalize_compile = function
  | None -> None
  | Some None -> None
  | Some (Some x) -> Some x

let validate_languages_config (cfgs : Openapi.yodacLanguagesConfig) =
  let rec loop seen (items : Openapi.yodacLanguageConfig list) =
    match items with
    | [] -> Ok ()
    | (cfg : Openapi.yodacLanguageConfig) :: tl ->
        if cfg.Openapi.language = "" then
          Error "Language name cannot be empty"
        else if List.mem cfg.Openapi.language seen then
          Error
            (Printf.sprintf "Duplicate language '%s' in config array"
               cfg.Openapi.language )
        else loop (cfg.Openapi.language :: seen) tl
  in
  loop [] cfgs

let runtime_of_languages_config (cfgs : Openapi.yodacLanguagesConfig) =
  let tbl = Hashtbl.create (max 16 (List.length cfgs)) in
  List.iter
    (fun (cfg : Openapi.yodacLanguageConfig) ->
      Hashtbl.replace tbl cfg.Openapi.language
        { ext= cfg.Openapi.ext
        ; image= cfg.Openapi.image
        ; tag= cfg.Openapi.tag
        ; compile= normalize_compile cfg.Openapi.compile
        ; run= cfg.Openapi.run } )
    cfgs ;
  tbl

let languages_config_of_runtime tbl =
  Hashtbl.fold
    (fun language cfg acc ->
      Openapi.create_yodacLanguageConfig ~language ~ext:cfg.ext
        ~image:cfg.image ~tag:cfg.tag ~compile:cfg.compile ~run:cfg.run ()
      :: acc )
    tbl []

let config_json_of_languages cfgs = Openapi.json_of_yodacLanguagesConfig cfgs

let languages_of_config_json json = Openapi.yodacLanguagesConfig_of_json json

let runtime_of_config_json json =
  json |> languages_of_config_json |> runtime_of_languages_config

let config_json_of_runtime tbl =
  tbl |> languages_config_of_runtime |> config_json_of_languages

let make_get_response_json ~config_json ~version ~updated_at ~updated_by =
  let config = languages_of_config_json config_json in
  let response =
    Openapi.create_yodacConfigGetResponse ~config ~version ~updated_at
      ~updated_by ()
  in
  Openapi.json_of_yodacConfigGetResponse response

let make_history_entry_json ~version ~timestamp ~changed_by ~action
    ~previous_config_json ~new_config =
  let previous_config =
    match previous_config_json with
    | None -> None
    | Some json -> Some (Openapi.json__of_json json)
  in
  let history =
    Openapi.create_yodacConfigHistoryEntry ~version ~timestamp ~changed_by
      ~action ~previous_config ~new_config ()
  in
  Openapi.json_of_yodacConfigHistoryEntry history

let make_history_response_json rows =
  let entries =
    List.filter_map
      (fun row ->
        try Some (Openapi.yodacConfigHistoryEntry_of_json row)
        with _ -> None )
      rows
  in
  Openapi.json_of_yodacConfigHistoryGetResponse entries

(** Devolve o JSON da configuração de linguagens em tempo de execução.
    @return JSON da configuração *)
let get_default_config_json () =
  let ic = open_in lang_config_path in
  let content =
    Fun.protect
      ~finally:(fun () -> close_in_noerr ic)
      (fun () -> really_input_string ic (in_channel_length ic))
  in
  match Yaml.of_string content with
  | Ok (`O fields) ->
      let languages =
        List.map
          (fun (lang, cfg) ->
            let yaml_required_string field =
              match Yaml.Util.find field cfg with
              | Ok (Some value) -> (
                match Yaml.Util.to_string value with
                | Ok x -> x
                | Error (`Msg msg) -> failwith msg )
              | Ok None ->
                  failwith
                    (Printf.sprintf
                       "Campo '%s' em configuração YAML de '%s' não \
                        encontrado"
                       field lang )
              | Error (`Msg msg) -> failwith msg
            in
            let ext = yaml_required_string "ext" in
            let image = yaml_required_string "image" in
            let tag = yaml_required_string "tag" in
            let run = yaml_required_string "run" in
            let compile =
              match Yaml.Util.find "compile" cfg with
              | Ok (Some (`String s)) -> Some s
              | Ok (Some `Null) | Ok None -> None
              | Ok _ -> failwith "campo 'compile' deve ser string ou null"
              | Error (`Msg msg) -> failwith msg
            in
            Openapi.create_yodacLanguageConfig ~language:lang ~ext ~image
              ~tag ~compile ~run () )
          fields
      in
      config_json_of_languages languages
  | Ok _ -> failwith "languagesv2.yaml: formato inválido"
  | Error (`Msg msg) -> failwith msg

(** Inicializa a configuração no Valkey se não existir.
    @return devolve [unit Lwt.t] *)
let init_config () =
  Lwt_pool.use Db.pool (fun conn ->
      Client.get conn config_key
      >>= function
      | Some _ -> Lwt.return_unit
      | None ->
          let config_json = get_default_config_json () in
          let timestamp = Helpers.date () in
          let new_config = languages_of_config_json config_json in
          let history_entry =
            make_history_entry_json ~version:1 ~timestamp ~changed_by:"yodac"
              ~action:"seed" ~previous_config_json:None ~new_config
          in
          Client.multi conn
          >>= fun _ ->
          Client.send_custom_request conn ["SET"; config_key; config_json]
          >>= fun _ ->
          Client.send_custom_request conn ["SET"; version_key; "1"]
          >>= fun _ ->
          Client.send_custom_request conn ["SET"; updated_at_key; timestamp]
          >>= fun _ ->
          Client.send_custom_request conn ["SET"; updated_by_key; "yodac"]
          >>= fun _ ->
          Client.send_custom_request conn
            ["RPUSH"; history_key; history_entry]
          >>= fun _ ->
          Client.exec conn
          >>= fun _ ->
          Lwt_io.printf "YodaC: seeded '%s' in Valkey (v1).\n%!" config_key )

(** Cache da versão da configuração em tempo de execução.
    Inicialmente carregada a partir do ficheiro local, mas pode ser atualizada
    a partir da configuração remota no Valkey. *)
let current_version = ref 0

(** Cache da configuração de linguagens em tempo de execução.
    Inicialmente carregada a partir do ficheiro local, mas pode ser atualizada
    a partir da configuração remota no Valkey. *)
let current_config : (string, lang_config_entry) Hashtbl.t ref =
  ref (Hashtbl.create 16)

(** Aplica a configuração atual em tempo de execução.
    @param version a versão da configuração
    @param json o JSON da configuração *)
let apply_config ~version json =
  let parsed = runtime_of_config_json json in
  current_config := parsed ;
  current_version := version

(** Atualiza a configuração em tempo de execução.
    @param force força a atualização mesmo que a versão não tenha mudado *)
let update_config ?(force = false) () =
  Lwt_pool.use Db.pool (fun conn ->
      Client.get conn version_key
      >>= fun remote_version_raw ->
      let remote_version =
        match remote_version_raw with Some x -> int_of_string x | None -> 0
      in
      let needs_reload = force || remote_version <> !current_version in
      if not needs_reload then Lwt.return_unit
      else
        Client.get conn config_key
        >>= function
        | None -> Lwt.return_unit
        | Some json -> (
          try
            apply_config ~version:remote_version json ;
            Lwt_io.printf
              "YodaC: configuração de linguagens recarregada (v%d) às %s\n%!"
              remote_version (Helpers.date ())
          with exn ->
            Lwt_io.eprintf
              "YodaC: falha ao recarregar configuração remota: %s\n%!"
              (Printexc.to_string exn) ) )

(** Inicializa a configuração em tempo de execução.
    Carrega a configuração a partir do ficheiro local e aplica.
    @raise Failure se o ficheiro de configuração não existir ou for inválido. *)
let init () =
  try
    let json = get_default_config_json () in
    apply_config ~version:0 json
  with exn ->
    Printf.eprintf
      "YodaC: falha ao carregar configuração local inicial: %s\n%!"
      (Printexc.to_string exn)
