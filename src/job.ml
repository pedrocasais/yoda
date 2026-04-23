(* Tipos *)
type lang = C | Cpp | OCaml | Python | Java | JavaScript

type testcase = Openapi.testCase

type job =
  { submission_id: int
  ; contest_id: int
  ; problem_id: int
  ; lang: lang
  ; source_code: string
  ; time_limit_ms: int
  ; memory_limit_mb: int
  ; testcases: testcase list }

type detail = Openapi.submissionDetails

type result = Openapi.submission

(* Funções auxiliares *)
let lang_of_string = function
  | "c" -> C
  | "cpp" -> Cpp
  | "ocaml" -> OCaml
  | "python" -> Python
  | "java" -> Java
  | "javascript" -> JavaScript
  | s -> failwith ("Linguagem desconhecida: " ^ s)

let string_of_lang = function
  | C -> "c"
  | Cpp -> "cpp"
  | OCaml -> "ml"
  | Python -> "py"
  | Java -> "java"
  | JavaScript -> "js"

(* Parse JSON -> job *)
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

let parse_job json_str =
  try
    let j = Yojson.Basic.from_string json_str in
    let open Yojson.Basic.Util in
    Some
      { submission_id= j |> member "submission_id" |> to_int
      ; contest_id= j |> member "contest_id" |> to_int
      ; problem_id= j |> member "problem_id" |> to_int
      ; lang= j |> member "language" |> to_string |> lang_of_string
      ; source_code= j |> member "source_code" |> to_string
      ; time_limit_ms= j |> member "time_limit_ms" |> to_int
      ; memory_limit_mb= j |> member "memory_limit_mb" |> to_int
      ; testcases=
          j |> member "testcases" |> to_list |> List.map parse_testcase }
  with _ -> None

let result_to_json r =
  Openapi.yojson_of_submission r |> Yojson.Safe.to_string
