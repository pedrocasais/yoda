(* Auto-generated from "types.atd" by atdml. *)

type userRole =
  | User
  | Judge
  | Admin

val userRole_of_yojson : Yojson.Safe.t -> userRole
val yojson_of_userRole : userRole -> Yojson.Safe.t
val userRole_of_json : string -> userRole
val json_of_userRole : userRole -> string

module UserRole : sig
  type nonrec t = userRole
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type user = {
  id: int;
  username: string;
  role: userRole;
  created_at: string;
}

val create_user : id:int -> username:string -> role:userRole -> created_at:string -> unit -> user
val user_of_yojson : Yojson.Safe.t -> user
val yojson_of_user : user -> Yojson.Safe.t
val user_of_json : string -> user
val json_of_user : user -> string

module User : sig
  type nonrec t = user
  val create : id:int -> username:string -> role:userRole -> created_at:string -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type testCase = {
  input: string;
  output: string;
  is_sample: bool;
}

val create_testCase : input:string -> output:string -> is_sample:bool -> unit -> testCase
val testCase_of_yojson : Yojson.Safe.t -> testCase
val yojson_of_testCase : testCase -> Yojson.Safe.t
val testCase_of_json : string -> testCase
val json_of_testCase : testCase -> string

module TestCase : sig
  type nonrec t = testCase
  val create : input:string -> output:string -> is_sample:bool -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type submissionDetails = {
  testcase_id: int;
  status: string;
  time_ms: int;
}

val create_submissionDetails : testcase_id:int -> status:string -> time_ms:int -> unit -> submissionDetails
val submissionDetails_of_yojson : Yojson.Safe.t -> submissionDetails
val yojson_of_submissionDetails : submissionDetails -> Yojson.Safe.t
val submissionDetails_of_json : string -> submissionDetails
val json_of_submissionDetails : submissionDetails -> string

module SubmissionDetails : sig
  type nonrec t = submissionDetails
  val create : testcase_id:int -> status:string -> time_ms:int -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type submission = {
  id: int;
  status: string;
  score: int;
  time_ms: int;
  memory_kb: int;
  details: submissionDetails list;
}

val create_submission : id:int -> status:string -> score:int -> time_ms:int -> memory_kb:int -> details:submissionDetails list -> unit -> submission
val submission_of_yojson : Yojson.Safe.t -> submission
val yojson_of_submission : submission -> Yojson.Safe.t
val submission_of_json : string -> submission
val json_of_submission : submission -> string

module Submission : sig
  type nonrec t = submission
  val create : id:int -> status:string -> score:int -> time_ms:int -> memory_kb:int -> details:submissionDetails list -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type solution = {
  contest_id: int;
  problem_id: int;
  language: string;
  source_code: string;
}

val create_solution : contest_id:int -> problem_id:int -> language:string -> source_code:string -> unit -> solution
val solution_of_yojson : Yojson.Safe.t -> solution
val yojson_of_solution : solution -> Yojson.Safe.t
val solution_of_json : string -> solution
val json_of_solution : solution -> string

module Solution : sig
  type nonrec t = solution
  val create : contest_id:int -> problem_id:int -> language:string -> source_code:string -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type json_ = Yojson.Safe.t

val json__of_yojson : Yojson.Safe.t -> json_
val yojson_of_json_ : json_ -> Yojson.Safe.t
val json__of_json : string -> json_
val json_of_json_ : json_ -> string

module Json_ : sig
  type nonrec t = json_
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type scoreboardEntry = {
  team: string;
  solved: int;
  penalty: int;
  problems: json_;
}

val create_scoreboardEntry : team:string -> solved:int -> penalty:int -> problems:json_ -> unit -> scoreboardEntry
val scoreboardEntry_of_yojson : Yojson.Safe.t -> scoreboardEntry
val yojson_of_scoreboardEntry : scoreboardEntry -> Yojson.Safe.t
val scoreboardEntry_of_json : string -> scoreboardEntry
val json_of_scoreboardEntry : scoreboardEntry -> string

module ScoreboardEntry : sig
  type nonrec t = scoreboardEntry
  val create : team:string -> solved:int -> penalty:int -> problems:json_ -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
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

val create_problem : code:string -> title:string -> time_limit_ms:int -> memory_limit_mb:int -> description:string -> input_spec:string -> output_spec:string -> unit -> problem
val problem_of_yojson : Yojson.Safe.t -> problem
val yojson_of_problem : problem -> Yojson.Safe.t
val problem_of_json : string -> problem
val json_of_problem : problem -> string

module Problem : sig
  type nonrec t = problem
  val create : code:string -> title:string -> time_limit_ms:int -> memory_limit_mb:int -> description:string -> input_spec:string -> output_spec:string -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type int64 = private int

val create_int64 : int -> int64
val int64_of_yojson : Yojson.Safe.t -> int64
val yojson_of_int64 : int64 -> Yojson.Safe.t
val int64_of_json : string -> int64
val json_of_int64 : int64 -> string

module Int64 : sig
  type nonrec t = int64
  val create : int -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type contestStatus =
  | Upcoming
  | Running
  | Finished

val contestStatus_of_yojson : Yojson.Safe.t -> contestStatus
val yojson_of_contestStatus : contestStatus -> Yojson.Safe.t
val contestStatus_of_json : string -> contestStatus
val json_of_contestStatus : contestStatus -> string

module ContestStatus : sig
  type nonrec t = contestStatus
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type contest = {
  id: int;
  title: string;
  description: string option;
  start_time: string;
  end_time: string;
  status: contestStatus;
}

val create_contest : id:int -> title:string -> ?description:string -> start_time:string -> end_time:string -> status:contestStatus -> unit -> contest
val contest_of_yojson : Yojson.Safe.t -> contest
val yojson_of_contest : contest -> Yojson.Safe.t
val contest_of_json : string -> contest
val json_of_contest : contest -> string

module Contest : sig
  type nonrec t = contest
  val create : id:int -> title:string -> ?description:string -> start_time:string -> end_time:string -> status:contestStatus -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type authToken = {
  token: string;
  user: user;
}

val create_authToken : token:string -> user:user -> unit -> authToken
val authToken_of_yojson : Yojson.Safe.t -> authToken
val yojson_of_authToken : authToken -> Yojson.Safe.t
val authToken_of_json : string -> authToken
val json_of_authToken : authToken -> string

module AuthToken : sig
  type nonrec t = authToken
  val create : token:string -> user:user -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

