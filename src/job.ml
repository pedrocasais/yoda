(** Tipos e funções de parsing para os jobs do YodaC. *)
type testcase = Openapi.testCase

(** Job de execução - submissão + limites + casos de teste. *)
type job =
  { submission_id: int
  ; user_id: int
  ; problem_id: int
  ; lang: string
  ; source_code: string
  ; time_limit_ms: int
  ; memory_limit_mb: int
  ; testcases: testcase list }

(** Resultao de um único caso de teste. *)
type detail = Openapi.submissionDetails

(** Resultado final agregado de todos os casos de teste. *)
type result = Openapi.submission

(** Parse de um caso de teste a partir de JSON. *)
let parse_testcase j =
  let open Yojson.Basic.Util in
  let id =
    match j |> member "id" with
    | `Null -> j |> member "testcase_id" |> to_int
    | value -> to_int value
  in
  let output =
    match j |> member "expected" with
    | `Null -> j |> member "output" |> to_string
    | value -> to_string value
  in
  { Openapi.id
  ; input= j |> member "input" |> to_string
  ; output
  ; is_sample= j |> member "is_sample" |> to_bool }

(** Parse de um job a partir de uma string JSON. 
    Devolve [None] se o JSON for inválido.*)
let parse_job json_str =
  try
    let j = Yojson.Basic.from_string json_str in
    let open Yojson.Basic.Util in
    Some
      { submission_id= j |> member "submission_id" |> to_int
      ; user_id= j |> member "user_id" |> to_int
      ; problem_id= j |> member "problem_id" |> to_int
      ; lang= j |> member "language" |> to_string
      ; source_code= j |> member "source_code" |> to_string
      ; time_limit_ms= j |> member "time_limit_ms" |> to_int
      ; memory_limit_mb= j |> member "memory_limit_mb" |> to_int
      ; testcases=
          j |> member "testcases" |> to_list |> List.map parse_testcase }
  with _ -> None

(** Serializa um resultado para JSON. *)
let result_to_json r =
  Openapi.yojson_of_submission r |> Yojson.Safe.to_string
