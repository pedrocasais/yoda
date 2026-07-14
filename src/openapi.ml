(* Auto-generated from "openapi.atd" by atdml. *)
[@@@ocaml.warning "-27-32-33-35-39"]

(* Inlined runtime — no external dependency needed. *)
module Atdml_runtime = struct
  (* Returns true iff the list has strictly more than [n] elements,
     without traversing past element n+1. *)
  let rec list_length_gt n = function
    | _ :: rest -> if n = 0 then true else list_length_gt (n - 1) rest
    | [] -> false

  module Yojson = struct
    let bad_type expected_type x =
      Printf.ksprintf failwith "expected %s, got: %s"
        expected_type (Yojson.Safe.to_string x)

    let bad_sum type_name x =
      Printf.ksprintf failwith "invalid variant for type '%s': %s"
        type_name (Yojson.Safe.to_string x)

    let missing_field type_name field_name =
      Printf.ksprintf failwith "missing field '%s' in object of type '%s'"
        field_name type_name

    let bool_of_yojson = function
      | `Bool b -> b
      | x -> bad_type "bool" x

    let yojson_of_bool b = `Bool b

    let int_of_yojson = function
      | `Int n -> n
      | x -> bad_type "int" x

    let yojson_of_int n = `Int n

    let float_of_yojson = function
      | `Float f -> f
      | `Int n -> Float.of_int n
      | x -> bad_type "float" x

    let yojson_of_float f = `Float f

    let string_of_yojson = function
      | `String s -> s
      | x -> bad_type "string" x

    let yojson_of_string s = `String s

    let unit_of_yojson = function
      | `Null -> ()
      | x -> bad_type "null" x

    let yojson_of_unit () = `Null

    let list_of_yojson f = function
      | `List xs -> List.map f xs
      | x -> bad_type "array" x

    let yojson_of_list f xs = `List (List.map f xs)

    let option_of_yojson f = function
      | `String "None" -> None
      | `List [`String "Some"; x] -> Some (f x)
      | x -> bad_type "option" x

    let yojson_of_option f = function
      | None -> `String "None"
      | Some x -> `List [`String "Some"; f x]

    let nullable_of_yojson f = function
      | `Null -> None
      | x -> Some (f x)

    let yojson_of_nullable f = function
      | None -> `Null
      | Some x -> f x

    let assoc_of_yojson f = function
      | `Assoc pairs -> List.map (fun (k, v) -> (k, f v)) pairs
      | x -> bad_type "object" x

    let yojson_of_assoc f xs =
      `Assoc (List.map (fun (k, v) -> (k, f v)) xs)
  end
end

type usersPostRequestRole =
  | User
  | Judge
  | Admin

let usersPostRequestRole_of_yojson (x : Yojson.Safe.t) : usersPostRequestRole =
  match x with
  | `String "user" -> User
  | `String "judge" -> Judge
  | `String "admin" -> Admin
  | _ -> Atdml_runtime.Yojson.bad_sum "usersPostRequestRole" x

let yojson_of_usersPostRequestRole (x : usersPostRequestRole) : Yojson.Safe.t =
  match x with
  | User -> `String "user"
  | Judge -> `String "judge"
  | Admin -> `String "admin"

let usersPostRequestRole_of_json s =
  usersPostRequestRole_of_yojson (Yojson.Safe.from_string s)

let json_of_usersPostRequestRole x =
  Yojson.Safe.to_string (yojson_of_usersPostRequestRole x)

module UsersPostRequestRole = struct
  type nonrec t = usersPostRequestRole
  let of_yojson = usersPostRequestRole_of_yojson
  let to_yojson = yojson_of_usersPostRequestRole
  let of_json = usersPostRequestRole_of_json
  let to_json = json_of_usersPostRequestRole
end

type usersPostRequest = {
  username: string;
  password: string;
  role: usersPostRequestRole;
}

let create_usersPostRequest ~username ~password ~role () : usersPostRequest =
  { username; password; role }

let usersPostRequest_of_yojson (x : Yojson.Safe.t) : usersPostRequest =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let username =
      match assoc_ "username" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "usersPostRequest" "username"
    in
    let password =
      match assoc_ "password" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "usersPostRequest" "password"
    in
    let role =
      match assoc_ "role" with
      | Some v -> usersPostRequestRole_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "usersPostRequest" "role"
    in
    { username; password; role }
  | _ -> Atdml_runtime.Yojson.bad_type "usersPostRequest" x

let yojson_of_usersPostRequest (x : usersPostRequest) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("username", Atdml_runtime.Yojson.yojson_of_string x.username)];
    [("password", Atdml_runtime.Yojson.yojson_of_string x.password)];
    [("role", yojson_of_usersPostRequestRole x.role)];
  ])

let usersPostRequest_of_json s =
  usersPostRequest_of_yojson (Yojson.Safe.from_string s)

let json_of_usersPostRequest x =
  Yojson.Safe.to_string (yojson_of_usersPostRequest x)

module UsersPostRequest = struct
  type nonrec t = usersPostRequest
  let create = create_usersPostRequest
  let of_yojson = usersPostRequest_of_yojson
  let to_yojson = yojson_of_usersPostRequest
  let of_json = usersPostRequest_of_json
  let to_json = json_of_usersPostRequest
end

type usersIdPutRequestRole =
  | User
  | Judge
  | Admin

let usersIdPutRequestRole_of_yojson (x : Yojson.Safe.t) : usersIdPutRequestRole =
  match x with
  | `String "user" -> User
  | `String "judge" -> Judge
  | `String "admin" -> Admin
  | _ -> Atdml_runtime.Yojson.bad_sum "usersIdPutRequestRole" x

let yojson_of_usersIdPutRequestRole (x : usersIdPutRequestRole) : Yojson.Safe.t =
  match x with
  | User -> `String "user"
  | Judge -> `String "judge"
  | Admin -> `String "admin"

let usersIdPutRequestRole_of_json s =
  usersIdPutRequestRole_of_yojson (Yojson.Safe.from_string s)

let json_of_usersIdPutRequestRole x =
  Yojson.Safe.to_string (yojson_of_usersIdPutRequestRole x)

module UsersIdPutRequestRole = struct
  type nonrec t = usersIdPutRequestRole
  let of_yojson = usersIdPutRequestRole_of_yojson
  let to_yojson = yojson_of_usersIdPutRequestRole
  let of_json = usersIdPutRequestRole_of_json
  let to_json = json_of_usersIdPutRequestRole
end

type usersIdPutRequest = {
  username: string option;
  role: usersIdPutRequestRole option;
}

let create_usersIdPutRequest ?username ?role () : usersIdPutRequest =
  { username; role }

let usersIdPutRequest_of_yojson (x : Yojson.Safe.t) : usersIdPutRequest =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let username =
      match assoc_ "username" with
      | None | Some `Null -> None
      | Some v -> Some (Atdml_runtime.Yojson.string_of_yojson v)
    in
    let role =
      match assoc_ "role" with
      | None | Some `Null -> None
      | Some v -> Some (usersIdPutRequestRole_of_yojson v)
    in
    { username; role }
  | _ -> Atdml_runtime.Yojson.bad_type "usersIdPutRequest" x

let yojson_of_usersIdPutRequest (x : usersIdPutRequest) : Yojson.Safe.t =
  `Assoc (List.concat [
    (match x.username with None -> [] | Some v -> [("username", Atdml_runtime.Yojson.yojson_of_string v)]);
    (match x.role with None -> [] | Some v -> [("role", yojson_of_usersIdPutRequestRole v)]);
  ])

let usersIdPutRequest_of_json s =
  usersIdPutRequest_of_yojson (Yojson.Safe.from_string s)

let json_of_usersIdPutRequest x =
  Yojson.Safe.to_string (yojson_of_usersIdPutRequest x)

module UsersIdPutRequest = struct
  type nonrec t = usersIdPutRequest
  let create = create_usersIdPutRequest
  let of_yojson = usersIdPutRequest_of_yojson
  let to_yojson = yojson_of_usersIdPutRequest
  let of_json = usersIdPutRequest_of_json
  let to_json = json_of_usersIdPutRequest
end

type userRole =
  | User
  | Judge
  | Admin

let userRole_of_yojson (x : Yojson.Safe.t) : userRole =
  match x with
  | `String "user" -> User
  | `String "judge" -> Judge
  | `String "admin" -> Admin
  | _ -> Atdml_runtime.Yojson.bad_sum "userRole" x

let yojson_of_userRole (x : userRole) : Yojson.Safe.t =
  match x with
  | User -> `String "user"
  | Judge -> `String "judge"
  | Admin -> `String "admin"

let userRole_of_json s =
  userRole_of_yojson (Yojson.Safe.from_string s)

let json_of_userRole x =
  Yojson.Safe.to_string (yojson_of_userRole x)

module UserRole = struct
  type nonrec t = userRole
  let of_yojson = userRole_of_yojson
  let to_yojson = yojson_of_userRole
  let of_json = userRole_of_json
  let to_json = json_of_userRole
end

type user = {
  id: int;
  username: string;
  role: userRole;
  created_at: string;
}

let create_user ~id ~username ~role ~created_at () : user =
  { id; username; role; created_at }

let user_of_yojson (x : Yojson.Safe.t) : user =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let id =
      match assoc_ "id" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "user" "id"
    in
    let username =
      match assoc_ "username" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "user" "username"
    in
    let role =
      match assoc_ "role" with
      | Some v -> userRole_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "user" "role"
    in
    let created_at =
      match assoc_ "created_at" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "user" "created_at"
    in
    { id; username; role; created_at }
  | _ -> Atdml_runtime.Yojson.bad_type "user" x

let yojson_of_user (x : user) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("id", Atdml_runtime.Yojson.yojson_of_int x.id)];
    [("username", Atdml_runtime.Yojson.yojson_of_string x.username)];
    [("role", yojson_of_userRole x.role)];
    [("created_at", Atdml_runtime.Yojson.yojson_of_string x.created_at)];
  ])

let user_of_json s =
  user_of_yojson (Yojson.Safe.from_string s)

let json_of_user x =
  Yojson.Safe.to_string (yojson_of_user x)

module User = struct
  type nonrec t = user
  let create = create_user
  let of_yojson = user_of_yojson
  let to_yojson = yojson_of_user
  let of_json = user_of_json
  let to_json = json_of_user
end

type usersGetResponse2 = user list

let usersGetResponse2_of_yojson (x : Yojson.Safe.t) : usersGetResponse2 =
  (Atdml_runtime.Yojson.list_of_yojson user_of_yojson) x

let yojson_of_usersGetResponse2 (x : usersGetResponse2) : Yojson.Safe.t =
  (Atdml_runtime.Yojson.yojson_of_list yojson_of_user) x

let usersGetResponse2_of_json s =
  usersGetResponse2_of_yojson (Yojson.Safe.from_string s)

let json_of_usersGetResponse2 x =
  Yojson.Safe.to_string (yojson_of_usersGetResponse2 x)

module UsersGetResponse2 = struct
  type nonrec t = usersGetResponse2
  let of_yojson = usersGetResponse2_of_yojson
  let to_yojson = yojson_of_usersGetResponse2
  let of_json = usersGetResponse2_of_json
  let to_json = json_of_usersGetResponse2
end

type testCase = {
  id: int;
  input: string;
  output: string;
  is_sample: bool;
}

let create_testCase ~id ~input ~output ~is_sample () : testCase =
  { id; input; output; is_sample }

let testCase_of_yojson (x : Yojson.Safe.t) : testCase =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let id =
      match assoc_ "id" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "testCase" "id"
    in
    let input =
      match assoc_ "input" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "testCase" "input"
    in
    let output =
      match assoc_ "output" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "testCase" "output"
    in
    let is_sample =
      match assoc_ "is_sample" with
      | Some v -> Atdml_runtime.Yojson.bool_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "testCase" "is_sample"
    in
    { id; input; output; is_sample }
  | _ -> Atdml_runtime.Yojson.bad_type "testCase" x

let yojson_of_testCase (x : testCase) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("id", Atdml_runtime.Yojson.yojson_of_int x.id)];
    [("input", Atdml_runtime.Yojson.yojson_of_string x.input)];
    [("output", Atdml_runtime.Yojson.yojson_of_string x.output)];
    [("is_sample", Atdml_runtime.Yojson.yojson_of_bool x.is_sample)];
  ])

let testCase_of_json s =
  testCase_of_yojson (Yojson.Safe.from_string s)

let json_of_testCase x =
  Yojson.Safe.to_string (yojson_of_testCase x)

module TestCase = struct
  type nonrec t = testCase
  let create = create_testCase
  let of_yojson = testCase_of_yojson
  let to_yojson = yojson_of_testCase
  let of_json = testCase_of_json
  let to_json = json_of_testCase
end

type submissionDetails = {
  testcase_id: int;
  status: string;
  time_ms: int;
}

let create_submissionDetails ~testcase_id ~status ~time_ms () : submissionDetails =
  { testcase_id; status; time_ms }

let submissionDetails_of_yojson (x : Yojson.Safe.t) : submissionDetails =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let testcase_id =
      match assoc_ "testcase_id" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "submissionDetails" "testcase_id"
    in
    let status =
      match assoc_ "status" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "submissionDetails" "status"
    in
    let time_ms =
      match assoc_ "time_ms" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "submissionDetails" "time_ms"
    in
    { testcase_id; status; time_ms }
  | _ -> Atdml_runtime.Yojson.bad_type "submissionDetails" x

let yojson_of_submissionDetails (x : submissionDetails) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("testcase_id", Atdml_runtime.Yojson.yojson_of_int x.testcase_id)];
    [("status", Atdml_runtime.Yojson.yojson_of_string x.status)];
    [("time_ms", Atdml_runtime.Yojson.yojson_of_int x.time_ms)];
  ])

let submissionDetails_of_json s =
  submissionDetails_of_yojson (Yojson.Safe.from_string s)

let json_of_submissionDetails x =
  Yojson.Safe.to_string (yojson_of_submissionDetails x)

module SubmissionDetails = struct
  type nonrec t = submissionDetails
  let create = create_submissionDetails
  let of_yojson = submissionDetails_of_yojson
  let to_yojson = yojson_of_submissionDetails
  let of_json = submissionDetails_of_json
  let to_json = json_of_submissionDetails
end

type submission = {
  id: int;
  problem_id: int;
  language: string option;
  status: string;
  score: int;
  time_ms: int;
  memory_kb: int;
  details: submissionDetails list;
}

let create_submission ~id ~problem_id ?language ~status ~score ~time_ms ~memory_kb ~details () : submission =
  { id; problem_id; language; status; score; time_ms; memory_kb; details }

let submission_of_yojson (x : Yojson.Safe.t) : submission =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let id =
      match assoc_ "id" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "submission" "id"
    in
    let problem_id =
      match assoc_ "problem_id" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "submission" "problem_id"
    in
    let language =
      match assoc_ "language" with
      | None | Some `Null -> None
      | Some v -> Some (Atdml_runtime.Yojson.string_of_yojson v)
    in
    let status =
      match assoc_ "status" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "submission" "status"
    in
    let score =
      match assoc_ "score" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "submission" "score"
    in
    let time_ms =
      match assoc_ "time_ms" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "submission" "time_ms"
    in
    let memory_kb =
      match assoc_ "memory_kb" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "submission" "memory_kb"
    in
    let details =
      match assoc_ "details" with
      | Some v -> (Atdml_runtime.Yojson.list_of_yojson submissionDetails_of_yojson) v
      | None -> Atdml_runtime.Yojson.missing_field "submission" "details"
    in
    { id; problem_id; language; status; score; time_ms; memory_kb; details }
  | _ -> Atdml_runtime.Yojson.bad_type "submission" x

let yojson_of_submission (x : submission) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("id", Atdml_runtime.Yojson.yojson_of_int x.id)];
    [("problem_id", Atdml_runtime.Yojson.yojson_of_int x.problem_id)];
    (match x.language with None -> [] | Some v -> [("language", Atdml_runtime.Yojson.yojson_of_string v)]);
    [("status", Atdml_runtime.Yojson.yojson_of_string x.status)];
    [("score", Atdml_runtime.Yojson.yojson_of_int x.score)];
    [("time_ms", Atdml_runtime.Yojson.yojson_of_int x.time_ms)];
    [("memory_kb", Atdml_runtime.Yojson.yojson_of_int x.memory_kb)];
    [("details", (Atdml_runtime.Yojson.yojson_of_list yojson_of_submissionDetails) x.details)];
  ])

let submission_of_json s =
  submission_of_yojson (Yojson.Safe.from_string s)

let json_of_submission x =
  Yojson.Safe.to_string (yojson_of_submission x)

module Submission = struct
  type nonrec t = submission
  let create = create_submission
  let of_yojson = submission_of_yojson
  let to_yojson = yojson_of_submission
  let of_json = submission_of_json
  let to_json = json_of_submission
end

type solution = {
  user_id: int;
  problem_id: int;
  language: string;
  source_code: string;
}

let create_solution ~user_id ~problem_id ~language ~source_code () : solution =
  { user_id; problem_id; language; source_code }

let solution_of_yojson (x : Yojson.Safe.t) : solution =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let user_id =
      match assoc_ "user_id" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "solution" "user_id"
    in
    let problem_id =
      match assoc_ "problem_id" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "solution" "problem_id"
    in
    let language =
      match assoc_ "language" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "solution" "language"
    in
    let source_code =
      match assoc_ "source_code" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "solution" "source_code"
    in
    { user_id; problem_id; language; source_code }
  | _ -> Atdml_runtime.Yojson.bad_type "solution" x

let yojson_of_solution (x : solution) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("user_id", Atdml_runtime.Yojson.yojson_of_int x.user_id)];
    [("problem_id", Atdml_runtime.Yojson.yojson_of_int x.problem_id)];
    [("language", Atdml_runtime.Yojson.yojson_of_string x.language)];
    [("source_code", Atdml_runtime.Yojson.yojson_of_string x.source_code)];
  ])

let solution_of_json s =
  solution_of_yojson (Yojson.Safe.from_string s)

let json_of_solution x =
  Yojson.Safe.to_string (yojson_of_solution x)

module Solution = struct
  type nonrec t = solution
  let create = create_solution
  let of_yojson = solution_of_yojson
  let to_yojson = yojson_of_solution
  let of_json = solution_of_json
  let to_json = json_of_solution
end

type json_ = Yojson.Safe.t

let json__of_yojson (x : Yojson.Safe.t) : json_ =
  (fun x -> x) x

let yojson_of_json_ (x : json_) : Yojson.Safe.t =
  (fun x -> x) x

let json__of_json s =
  json__of_yojson (Yojson.Safe.from_string s)

let json_of_json_ x =
  Yojson.Safe.to_string (yojson_of_json_ x)

module Json_ = struct
  type nonrec t = json_
  let of_yojson = json__of_yojson
  let to_yojson = yojson_of_json_
  let of_json = json__of_json
  let to_json = json_of_json_
end

type scoreboardEntry = {
  team: string;
  solved: int;
  penalty: int;
  problems: json_;
}

let create_scoreboardEntry ~team ~solved ~penalty ~problems () : scoreboardEntry =
  { team; solved; penalty; problems }

let scoreboardEntry_of_yojson (x : Yojson.Safe.t) : scoreboardEntry =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let team =
      match assoc_ "team" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "scoreboardEntry" "team"
    in
    let solved =
      match assoc_ "solved" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "scoreboardEntry" "solved"
    in
    let penalty =
      match assoc_ "penalty" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "scoreboardEntry" "penalty"
    in
    let problems =
      match assoc_ "problems" with
      | Some v -> json__of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "scoreboardEntry" "problems"
    in
    { team; solved; penalty; problems }
  | _ -> Atdml_runtime.Yojson.bad_type "scoreboardEntry" x

let yojson_of_scoreboardEntry (x : scoreboardEntry) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("team", Atdml_runtime.Yojson.yojson_of_string x.team)];
    [("solved", Atdml_runtime.Yojson.yojson_of_int x.solved)];
    [("penalty", Atdml_runtime.Yojson.yojson_of_int x.penalty)];
    [("problems", yojson_of_json_ x.problems)];
  ])

let scoreboardEntry_of_json s =
  scoreboardEntry_of_yojson (Yojson.Safe.from_string s)

let json_of_scoreboardEntry x =
  Yojson.Safe.to_string (yojson_of_scoreboardEntry x)

module ScoreboardEntry = struct
  type nonrec t = scoreboardEntry
  let create = create_scoreboardEntry
  let of_yojson = scoreboardEntry_of_yojson
  let to_yojson = yojson_of_scoreboardEntry
  let of_json = scoreboardEntry_of_json
  let to_json = json_of_scoreboardEntry
end

type problemsIdTestcasesGetResponse2 = testCase list

let problemsIdTestcasesGetResponse2_of_yojson (x : Yojson.Safe.t) : problemsIdTestcasesGetResponse2 =
  (Atdml_runtime.Yojson.list_of_yojson testCase_of_yojson) x

let yojson_of_problemsIdTestcasesGetResponse2 (x : problemsIdTestcasesGetResponse2) : Yojson.Safe.t =
  (Atdml_runtime.Yojson.yojson_of_list yojson_of_testCase) x

let problemsIdTestcasesGetResponse2_of_json s =
  problemsIdTestcasesGetResponse2_of_yojson (Yojson.Safe.from_string s)

let json_of_problemsIdTestcasesGetResponse2 x =
  Yojson.Safe.to_string (yojson_of_problemsIdTestcasesGetResponse2 x)

module ProblemsIdTestcasesGetResponse2 = struct
  type nonrec t = problemsIdTestcasesGetResponse2
  let of_yojson = problemsIdTestcasesGetResponse2_of_yojson
  let to_yojson = yojson_of_problemsIdTestcasesGetResponse2
  let of_json = problemsIdTestcasesGetResponse2_of_json
  let to_json = json_of_problemsIdTestcasesGetResponse2
end

type problem = {
  code: string;
  title: string;
  time_limit_ms: int;
  memory_limit_mb: int;
  description: string;
  input_spec: string;
  output_spec: string;
}

let create_problem ~code ~title ~time_limit_ms ~memory_limit_mb ~description ~input_spec ~output_spec () : problem =
  { code; title; time_limit_ms; memory_limit_mb; description; input_spec; output_spec }

let problem_of_yojson (x : Yojson.Safe.t) : problem =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let code =
      match assoc_ "code" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "problem" "code"
    in
    let title =
      match assoc_ "title" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "problem" "title"
    in
    let time_limit_ms =
      match assoc_ "time_limit_ms" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "problem" "time_limit_ms"
    in
    let memory_limit_mb =
      match assoc_ "memory_limit_mb" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "problem" "memory_limit_mb"
    in
    let description =
      match assoc_ "description" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "problem" "description"
    in
    let input_spec =
      match assoc_ "input_spec" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "problem" "input_spec"
    in
    let output_spec =
      match assoc_ "output_spec" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "problem" "output_spec"
    in
    { code; title; time_limit_ms; memory_limit_mb; description; input_spec; output_spec }
  | _ -> Atdml_runtime.Yojson.bad_type "problem" x

let yojson_of_problem (x : problem) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("code", Atdml_runtime.Yojson.yojson_of_string x.code)];
    [("title", Atdml_runtime.Yojson.yojson_of_string x.title)];
    [("time_limit_ms", Atdml_runtime.Yojson.yojson_of_int x.time_limit_ms)];
    [("memory_limit_mb", Atdml_runtime.Yojson.yojson_of_int x.memory_limit_mb)];
    [("description", Atdml_runtime.Yojson.yojson_of_string x.description)];
    [("input_spec", Atdml_runtime.Yojson.yojson_of_string x.input_spec)];
    [("output_spec", Atdml_runtime.Yojson.yojson_of_string x.output_spec)];
  ])

let problem_of_json s =
  problem_of_yojson (Yojson.Safe.from_string s)

let json_of_problem x =
  Yojson.Safe.to_string (yojson_of_problem x)

module Problem = struct
  type nonrec t = problem
  let create = create_problem
  let of_yojson = problem_of_yojson
  let to_yojson = yojson_of_problem
  let of_json = problem_of_json
  let to_json = json_of_problem
end

type int64 = int

let create_int64 (x : int) : int64 = x


let int64_of_yojson (x : Yojson.Safe.t) : int64 =
  Atdml_runtime.Yojson.int_of_yojson x

let yojson_of_int64 (x : int64) : Yojson.Safe.t =
  Atdml_runtime.Yojson.yojson_of_int x

let int64_of_json s =
  int64_of_yojson (Yojson.Safe.from_string s)

let json_of_int64 x =
  Yojson.Safe.to_string (yojson_of_int64 x)

module Int64 = struct
  type nonrec t = int64
  let create = create_int64
  let of_yojson = int64_of_yojson
  let to_yojson = yojson_of_int64
  let of_json = int64_of_json
  let to_json = json_of_int64
end

type contestsPostRequest = {
  title: string;
  description: string option;
  start_time: string;
  end_time: string;
}

let create_contestsPostRequest ~title ?description ~start_time ~end_time () : contestsPostRequest =
  { title; description; start_time; end_time }

let contestsPostRequest_of_yojson (x : Yojson.Safe.t) : contestsPostRequest =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let title =
      match assoc_ "title" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "contestsPostRequest" "title"
    in
    let description =
      match assoc_ "description" with
      | None | Some `Null -> None
      | Some v -> Some (Atdml_runtime.Yojson.string_of_yojson v)
    in
    let start_time =
      match assoc_ "start_time" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "contestsPostRequest" "start_time"
    in
    let end_time =
      match assoc_ "end_time" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "contestsPostRequest" "end_time"
    in
    { title; description; start_time; end_time }
  | _ -> Atdml_runtime.Yojson.bad_type "contestsPostRequest" x

let yojson_of_contestsPostRequest (x : contestsPostRequest) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("title", Atdml_runtime.Yojson.yojson_of_string x.title)];
    (match x.description with None -> [] | Some v -> [("description", Atdml_runtime.Yojson.yojson_of_string v)]);
    [("start_time", Atdml_runtime.Yojson.yojson_of_string x.start_time)];
    [("end_time", Atdml_runtime.Yojson.yojson_of_string x.end_time)];
  ])

let contestsPostRequest_of_json s =
  contestsPostRequest_of_yojson (Yojson.Safe.from_string s)

let json_of_contestsPostRequest x =
  Yojson.Safe.to_string (yojson_of_contestsPostRequest x)

module ContestsPostRequest = struct
  type nonrec t = contestsPostRequest
  let create = create_contestsPostRequest
  let of_yojson = contestsPostRequest_of_yojson
  let to_yojson = yojson_of_contestsPostRequest
  let of_json = contestsPostRequest_of_json
  let to_json = json_of_contestsPostRequest
end

type contestsIdScoreboardGetResponse2 = scoreboardEntry list

let contestsIdScoreboardGetResponse2_of_yojson (x : Yojson.Safe.t) : contestsIdScoreboardGetResponse2 =
  (Atdml_runtime.Yojson.list_of_yojson scoreboardEntry_of_yojson) x

let yojson_of_contestsIdScoreboardGetResponse2 (x : contestsIdScoreboardGetResponse2) : Yojson.Safe.t =
  (Atdml_runtime.Yojson.yojson_of_list yojson_of_scoreboardEntry) x

let contestsIdScoreboardGetResponse2_of_json s =
  contestsIdScoreboardGetResponse2_of_yojson (Yojson.Safe.from_string s)

let json_of_contestsIdScoreboardGetResponse2 x =
  Yojson.Safe.to_string (yojson_of_contestsIdScoreboardGetResponse2 x)

module ContestsIdScoreboardGetResponse2 = struct
  type nonrec t = contestsIdScoreboardGetResponse2
  let of_yojson = contestsIdScoreboardGetResponse2_of_yojson
  let to_yojson = yojson_of_contestsIdScoreboardGetResponse2
  let of_json = contestsIdScoreboardGetResponse2_of_json
  let to_json = json_of_contestsIdScoreboardGetResponse2
end

type contestsIdPutRequestStatus =
  | Upcoming
  | Running
  | Finished

let contestsIdPutRequestStatus_of_yojson (x : Yojson.Safe.t) : contestsIdPutRequestStatus =
  match x with
  | `String "upcoming" -> Upcoming
  | `String "running" -> Running
  | `String "finished" -> Finished
  | _ -> Atdml_runtime.Yojson.bad_sum "contestsIdPutRequestStatus" x

let yojson_of_contestsIdPutRequestStatus (x : contestsIdPutRequestStatus) : Yojson.Safe.t =
  match x with
  | Upcoming -> `String "upcoming"
  | Running -> `String "running"
  | Finished -> `String "finished"

let contestsIdPutRequestStatus_of_json s =
  contestsIdPutRequestStatus_of_yojson (Yojson.Safe.from_string s)

let json_of_contestsIdPutRequestStatus x =
  Yojson.Safe.to_string (yojson_of_contestsIdPutRequestStatus x)

module ContestsIdPutRequestStatus = struct
  type nonrec t = contestsIdPutRequestStatus
  let of_yojson = contestsIdPutRequestStatus_of_yojson
  let to_yojson = yojson_of_contestsIdPutRequestStatus
  let of_json = contestsIdPutRequestStatus_of_json
  let to_json = json_of_contestsIdPutRequestStatus
end

type contestsIdPutRequest = {
  title: string option;
  description: string option;
  start_time: string option;
  end_time: string option;
  status: contestsIdPutRequestStatus option;
}

let create_contestsIdPutRequest ?title ?description ?start_time ?end_time ?status () : contestsIdPutRequest =
  { title; description; start_time; end_time; status }

let contestsIdPutRequest_of_yojson (x : Yojson.Safe.t) : contestsIdPutRequest =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let title =
      match assoc_ "title" with
      | None | Some `Null -> None
      | Some v -> Some (Atdml_runtime.Yojson.string_of_yojson v)
    in
    let description =
      match assoc_ "description" with
      | None | Some `Null -> None
      | Some v -> Some (Atdml_runtime.Yojson.string_of_yojson v)
    in
    let start_time =
      match assoc_ "start_time" with
      | None | Some `Null -> None
      | Some v -> Some (Atdml_runtime.Yojson.string_of_yojson v)
    in
    let end_time =
      match assoc_ "end_time" with
      | None | Some `Null -> None
      | Some v -> Some (Atdml_runtime.Yojson.string_of_yojson v)
    in
    let status =
      match assoc_ "status" with
      | None | Some `Null -> None
      | Some v -> Some (contestsIdPutRequestStatus_of_yojson v)
    in
    { title; description; start_time; end_time; status }
  | _ -> Atdml_runtime.Yojson.bad_type "contestsIdPutRequest" x

let yojson_of_contestsIdPutRequest (x : contestsIdPutRequest) : Yojson.Safe.t =
  `Assoc (List.concat [
    (match x.title with None -> [] | Some v -> [("title", Atdml_runtime.Yojson.yojson_of_string v)]);
    (match x.description with None -> [] | Some v -> [("description", Atdml_runtime.Yojson.yojson_of_string v)]);
    (match x.start_time with None -> [] | Some v -> [("start_time", Atdml_runtime.Yojson.yojson_of_string v)]);
    (match x.end_time with None -> [] | Some v -> [("end_time", Atdml_runtime.Yojson.yojson_of_string v)]);
    (match x.status with None -> [] | Some v -> [("status", yojson_of_contestsIdPutRequestStatus v)]);
  ])

let contestsIdPutRequest_of_json s =
  contestsIdPutRequest_of_yojson (Yojson.Safe.from_string s)

let json_of_contestsIdPutRequest x =
  Yojson.Safe.to_string (yojson_of_contestsIdPutRequest x)

module ContestsIdPutRequest = struct
  type nonrec t = contestsIdPutRequest
  let create = create_contestsIdPutRequest
  let of_yojson = contestsIdPutRequest_of_yojson
  let to_yojson = yojson_of_contestsIdPutRequest
  let of_json = contestsIdPutRequest_of_json
  let to_json = json_of_contestsIdPutRequest
end

type contestStatus =
  | Upcoming
  | Running
  | Finished

let contestStatus_of_yojson (x : Yojson.Safe.t) : contestStatus =
  match x with
  | `String "upcoming" -> Upcoming
  | `String "running" -> Running
  | `String "finished" -> Finished
  | _ -> Atdml_runtime.Yojson.bad_sum "contestStatus" x

let yojson_of_contestStatus (x : contestStatus) : Yojson.Safe.t =
  match x with
  | Upcoming -> `String "upcoming"
  | Running -> `String "running"
  | Finished -> `String "finished"

let contestStatus_of_json s =
  contestStatus_of_yojson (Yojson.Safe.from_string s)

let json_of_contestStatus x =
  Yojson.Safe.to_string (yojson_of_contestStatus x)

module ContestStatus = struct
  type nonrec t = contestStatus
  let of_yojson = contestStatus_of_yojson
  let to_yojson = yojson_of_contestStatus
  let of_json = contestStatus_of_json
  let to_json = json_of_contestStatus
end

type contest = {
  id: int;
  title: string;
  description: string option;
  start_time: string;
  end_time: string;
  status: contestStatus;
}

let create_contest ~id ~title ?description ~start_time ~end_time ~status () : contest =
  { id; title; description; start_time; end_time; status }

let contest_of_yojson (x : Yojson.Safe.t) : contest =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let id =
      match assoc_ "id" with
      | Some v -> Atdml_runtime.Yojson.int_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "contest" "id"
    in
    let title =
      match assoc_ "title" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "contest" "title"
    in
    let description =
      match assoc_ "description" with
      | None | Some `Null -> None
      | Some v -> Some (Atdml_runtime.Yojson.string_of_yojson v)
    in
    let start_time =
      match assoc_ "start_time" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "contest" "start_time"
    in
    let end_time =
      match assoc_ "end_time" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "contest" "end_time"
    in
    let status =
      match assoc_ "status" with
      | Some v -> contestStatus_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "contest" "status"
    in
    { id; title; description; start_time; end_time; status }
  | _ -> Atdml_runtime.Yojson.bad_type "contest" x

let yojson_of_contest (x : contest) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("id", Atdml_runtime.Yojson.yojson_of_int x.id)];
    [("title", Atdml_runtime.Yojson.yojson_of_string x.title)];
    (match x.description with None -> [] | Some v -> [("description", Atdml_runtime.Yojson.yojson_of_string v)]);
    [("start_time", Atdml_runtime.Yojson.yojson_of_string x.start_time)];
    [("end_time", Atdml_runtime.Yojson.yojson_of_string x.end_time)];
    [("status", yojson_of_contestStatus x.status)];
  ])

let contest_of_json s =
  contest_of_yojson (Yojson.Safe.from_string s)

let json_of_contest x =
  Yojson.Safe.to_string (yojson_of_contest x)

module Contest = struct
  type nonrec t = contest
  let create = create_contest
  let of_yojson = contest_of_yojson
  let to_yojson = yojson_of_contest
  let of_json = contest_of_json
  let to_json = json_of_contest
end

type contestsGetResponse2 = contest list

let contestsGetResponse2_of_yojson (x : Yojson.Safe.t) : contestsGetResponse2 =
  (Atdml_runtime.Yojson.list_of_yojson contest_of_yojson) x

let yojson_of_contestsGetResponse2 (x : contestsGetResponse2) : Yojson.Safe.t =
  (Atdml_runtime.Yojson.yojson_of_list yojson_of_contest) x

let contestsGetResponse2_of_json s =
  contestsGetResponse2_of_yojson (Yojson.Safe.from_string s)

let json_of_contestsGetResponse2 x =
  Yojson.Safe.to_string (yojson_of_contestsGetResponse2 x)

module ContestsGetResponse2 = struct
  type nonrec t = contestsGetResponse2
  let of_yojson = contestsGetResponse2_of_yojson
  let to_yojson = yojson_of_contestsGetResponse2
  let of_json = contestsGetResponse2_of_json
  let to_json = json_of_contestsGetResponse2
end

type contestsContestsidProblemsGetResponse2 = problem list

let contestsContestsidProblemsGetResponse2_of_yojson (x : Yojson.Safe.t) : contestsContestsidProblemsGetResponse2 =
  (Atdml_runtime.Yojson.list_of_yojson problem_of_yojson) x

let yojson_of_contestsContestsidProblemsGetResponse2 (x : contestsContestsidProblemsGetResponse2) : Yojson.Safe.t =
  (Atdml_runtime.Yojson.yojson_of_list yojson_of_problem) x

let contestsContestsidProblemsGetResponse2_of_json s =
  contestsContestsidProblemsGetResponse2_of_yojson (Yojson.Safe.from_string s)

let json_of_contestsContestsidProblemsGetResponse2 x =
  Yojson.Safe.to_string (yojson_of_contestsContestsidProblemsGetResponse2 x)

module ContestsContestsidProblemsGetResponse2 = struct
  type nonrec t = contestsContestsidProblemsGetResponse2
  let of_yojson = contestsContestsidProblemsGetResponse2_of_yojson
  let to_yojson = yojson_of_contestsContestsidProblemsGetResponse2
  let of_json = contestsContestsidProblemsGetResponse2_of_json
  let to_json = json_of_contestsContestsidProblemsGetResponse2
end

type contestsContestidSubmissionsGetResponse2 = submission list

let contestsContestidSubmissionsGetResponse2_of_yojson (x : Yojson.Safe.t) : contestsContestidSubmissionsGetResponse2 =
  (Atdml_runtime.Yojson.list_of_yojson submission_of_yojson) x

let yojson_of_contestsContestidSubmissionsGetResponse2 (x : contestsContestidSubmissionsGetResponse2) : Yojson.Safe.t =
  (Atdml_runtime.Yojson.yojson_of_list yojson_of_submission) x

let contestsContestidSubmissionsGetResponse2_of_json s =
  contestsContestidSubmissionsGetResponse2_of_yojson (Yojson.Safe.from_string s)

let json_of_contestsContestidSubmissionsGetResponse2 x =
  Yojson.Safe.to_string (yojson_of_contestsContestidSubmissionsGetResponse2 x)

module ContestsContestidSubmissionsGetResponse2 = struct
  type nonrec t = contestsContestidSubmissionsGetResponse2
  let of_yojson = contestsContestidSubmissionsGetResponse2_of_yojson
  let to_yojson = yojson_of_contestsContestidSubmissionsGetResponse2
  let of_json = contestsContestidSubmissionsGetResponse2_of_json
  let to_json = json_of_contestsContestidSubmissionsGetResponse2
end

type authToken = {
  token: string;
  user: user;
}

let create_authToken ~token ~user () : authToken =
  { token; user }

let authToken_of_yojson (x : Yojson.Safe.t) : authToken =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let token =
      match assoc_ "token" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "authToken" "token"
    in
    let user =
      match assoc_ "user" with
      | Some v -> user_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "authToken" "user"
    in
    { token; user }
  | _ -> Atdml_runtime.Yojson.bad_type "authToken" x

let yojson_of_authToken (x : authToken) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("token", Atdml_runtime.Yojson.yojson_of_string x.token)];
    [("user", yojson_of_user x.user)];
  ])

let authToken_of_json s =
  authToken_of_yojson (Yojson.Safe.from_string s)

let json_of_authToken x =
  Yojson.Safe.to_string (yojson_of_authToken x)

module AuthToken = struct
  type nonrec t = authToken
  let create = create_authToken
  let of_yojson = authToken_of_yojson
  let to_yojson = yojson_of_authToken
  let of_json = authToken_of_json
  let to_json = json_of_authToken
end

type authLoginPostResponse41 = {
  error: string;
}

let create_authLoginPostResponse41 ~error () : authLoginPostResponse41 =
  { error }

let authLoginPostResponse41_of_yojson (x : Yojson.Safe.t) : authLoginPostResponse41 =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let error =
      match assoc_ "error" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "authLoginPostResponse41" "error"
    in
    { error }
  | _ -> Atdml_runtime.Yojson.bad_type "authLoginPostResponse41" x

let yojson_of_authLoginPostResponse41 (x : authLoginPostResponse41) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("error", Atdml_runtime.Yojson.yojson_of_string x.error)];
  ])

let authLoginPostResponse41_of_json s =
  authLoginPostResponse41_of_yojson (Yojson.Safe.from_string s)

let json_of_authLoginPostResponse41 x =
  Yojson.Safe.to_string (yojson_of_authLoginPostResponse41 x)

module AuthLoginPostResponse41 = struct
  type nonrec t = authLoginPostResponse41
  let create = create_authLoginPostResponse41
  let of_yojson = authLoginPostResponse41_of_yojson
  let to_yojson = yojson_of_authLoginPostResponse41
  let of_json = authLoginPostResponse41_of_json
  let to_json = json_of_authLoginPostResponse41
end

type authLoginPostRequest = {
  username: string;
  password: string;
}

let create_authLoginPostRequest ~username ~password () : authLoginPostRequest =
  { username; password }

let authLoginPostRequest_of_yojson (x : Yojson.Safe.t) : authLoginPostRequest =
  match x with
  | `Assoc fields ->
    (* Duplicate JSON keys: behavior is unspecified (RFC 8259 §4 says keys SHOULD
       be unique). Below the threshold, List.assoc_opt returns the first binding;
       above it, the hashtable returns the last. *)
    let assoc_ =
      if Atdml_runtime.list_length_gt 5 fields then
        let tbl = Hashtbl.create 16 in
        List.iter (fun (k, v) -> Hashtbl.add tbl k v) fields;
        (fun key -> Hashtbl.find_opt tbl key)
      else (fun key -> List.assoc_opt key fields)
    in
    let username =
      match assoc_ "username" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "authLoginPostRequest" "username"
    in
    let password =
      match assoc_ "password" with
      | Some v -> Atdml_runtime.Yojson.string_of_yojson v
      | None -> Atdml_runtime.Yojson.missing_field "authLoginPostRequest" "password"
    in
    { username; password }
  | _ -> Atdml_runtime.Yojson.bad_type "authLoginPostRequest" x

let yojson_of_authLoginPostRequest (x : authLoginPostRequest) : Yojson.Safe.t =
  `Assoc (List.concat [
    [("username", Atdml_runtime.Yojson.yojson_of_string x.username)];
    [("password", Atdml_runtime.Yojson.yojson_of_string x.password)];
  ])

let authLoginPostRequest_of_json s =
  authLoginPostRequest_of_yojson (Yojson.Safe.from_string s)

let json_of_authLoginPostRequest x =
  Yojson.Safe.to_string (yojson_of_authLoginPostRequest x)

module AuthLoginPostRequest = struct
  type nonrec t = authLoginPostRequest
  let create = create_authLoginPostRequest
  let of_yojson = authLoginPostRequest_of_yojson
  let to_yojson = yojson_of_authLoginPostRequest
  let of_json = authLoginPostRequest_of_json
  let to_json = json_of_authLoginPostRequest
end

