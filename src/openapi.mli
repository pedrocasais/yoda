(* Auto-generated from "openapi.atd" by atdml. *)

type usersPostRequestRole =
  | User
  | Judge
  | Admin

val usersPostRequestRole_of_yojson : Yojson.Safe.t -> usersPostRequestRole
val yojson_of_usersPostRequestRole : usersPostRequestRole -> Yojson.Safe.t
val usersPostRequestRole_of_json : string -> usersPostRequestRole
val json_of_usersPostRequestRole : usersPostRequestRole -> string

module UsersPostRequestRole : sig
  type nonrec t = usersPostRequestRole
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type usersPostRequest = {
  username: string;
  password: string;
  role: usersPostRequestRole;
}

val create_usersPostRequest : username:string -> password:string -> role:usersPostRequestRole -> unit -> usersPostRequest
val usersPostRequest_of_yojson : Yojson.Safe.t -> usersPostRequest
val yojson_of_usersPostRequest : usersPostRequest -> Yojson.Safe.t
val usersPostRequest_of_json : string -> usersPostRequest
val json_of_usersPostRequest : usersPostRequest -> string

module UsersPostRequest : sig
  type nonrec t = usersPostRequest
  val create : username:string -> password:string -> role:usersPostRequestRole -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type usersIdPutRequestRole =
  | User
  | Judge
  | Admin

val usersIdPutRequestRole_of_yojson : Yojson.Safe.t -> usersIdPutRequestRole
val yojson_of_usersIdPutRequestRole : usersIdPutRequestRole -> Yojson.Safe.t
val usersIdPutRequestRole_of_json : string -> usersIdPutRequestRole
val json_of_usersIdPutRequestRole : usersIdPutRequestRole -> string

module UsersIdPutRequestRole : sig
  type nonrec t = usersIdPutRequestRole
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type usersIdPutRequest = {
  username: string option;
  role: usersIdPutRequestRole option;
}

val create_usersIdPutRequest : ?username:string -> ?role:usersIdPutRequestRole -> unit -> usersIdPutRequest
val usersIdPutRequest_of_yojson : Yojson.Safe.t -> usersIdPutRequest
val yojson_of_usersIdPutRequest : usersIdPutRequest -> Yojson.Safe.t
val usersIdPutRequest_of_json : string -> usersIdPutRequest
val json_of_usersIdPutRequest : usersIdPutRequest -> string

module UsersIdPutRequest : sig
  type nonrec t = usersIdPutRequest
  val create : ?username:string -> ?role:usersIdPutRequestRole -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

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

type usersGetResponse2 = user list

val usersGetResponse2_of_yojson : Yojson.Safe.t -> usersGetResponse2
val yojson_of_usersGetResponse2 : usersGetResponse2 -> Yojson.Safe.t
val usersGetResponse2_of_json : string -> usersGetResponse2
val json_of_usersGetResponse2 : usersGetResponse2 -> string

module UsersGetResponse2 : sig
  type nonrec t = usersGetResponse2
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type testCase = {
  id: int;
  input: string;
  output: string;
  is_sample: bool;
}

val create_testCase : id:int -> input:string -> output:string -> is_sample:bool -> unit -> testCase
val testCase_of_yojson : Yojson.Safe.t -> testCase
val yojson_of_testCase : testCase -> Yojson.Safe.t
val testCase_of_json : string -> testCase
val json_of_testCase : testCase -> string

module TestCase : sig
  type nonrec t = testCase
  val create : id:int -> input:string -> output:string -> is_sample:bool -> unit -> t
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
  user_id: int;
  problem_id: int;
  language: string;
  source_code: string;
}

val create_solution : user_id:int -> problem_id:int -> language:string -> source_code:string -> unit -> solution
val solution_of_yojson : Yojson.Safe.t -> solution
val yojson_of_solution : solution -> Yojson.Safe.t
val solution_of_json : string -> solution
val json_of_solution : solution -> string

module Solution : sig
  type nonrec t = solution
  val create : user_id:int -> problem_id:int -> language:string -> source_code:string -> unit -> t
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

type problemsIdTestcasesGetResponse2 = testCase list

val problemsIdTestcasesGetResponse2_of_yojson : Yojson.Safe.t -> problemsIdTestcasesGetResponse2
val yojson_of_problemsIdTestcasesGetResponse2 : problemsIdTestcasesGetResponse2 -> Yojson.Safe.t
val problemsIdTestcasesGetResponse2_of_json : string -> problemsIdTestcasesGetResponse2
val json_of_problemsIdTestcasesGetResponse2 : problemsIdTestcasesGetResponse2 -> string

module ProblemsIdTestcasesGetResponse2 : sig
  type nonrec t = problemsIdTestcasesGetResponse2
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

type contestsPostRequest = {
  title: string;
  description: string option;
  start_time: string;
  end_time: string;
}

val create_contestsPostRequest : title:string -> ?description:string -> start_time:string -> end_time:string -> unit -> contestsPostRequest
val contestsPostRequest_of_yojson : Yojson.Safe.t -> contestsPostRequest
val yojson_of_contestsPostRequest : contestsPostRequest -> Yojson.Safe.t
val contestsPostRequest_of_json : string -> contestsPostRequest
val json_of_contestsPostRequest : contestsPostRequest -> string

module ContestsPostRequest : sig
  type nonrec t = contestsPostRequest
  val create : title:string -> ?description:string -> start_time:string -> end_time:string -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type contestsIdScoreboardGetResponse2 = scoreboardEntry list

val contestsIdScoreboardGetResponse2_of_yojson : Yojson.Safe.t -> contestsIdScoreboardGetResponse2
val yojson_of_contestsIdScoreboardGetResponse2 : contestsIdScoreboardGetResponse2 -> Yojson.Safe.t
val contestsIdScoreboardGetResponse2_of_json : string -> contestsIdScoreboardGetResponse2
val json_of_contestsIdScoreboardGetResponse2 : contestsIdScoreboardGetResponse2 -> string

module ContestsIdScoreboardGetResponse2 : sig
  type nonrec t = contestsIdScoreboardGetResponse2
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type contestsIdPutRequestStatus =
  | Upcoming
  | Running
  | Finished

val contestsIdPutRequestStatus_of_yojson : Yojson.Safe.t -> contestsIdPutRequestStatus
val yojson_of_contestsIdPutRequestStatus : contestsIdPutRequestStatus -> Yojson.Safe.t
val contestsIdPutRequestStatus_of_json : string -> contestsIdPutRequestStatus
val json_of_contestsIdPutRequestStatus : contestsIdPutRequestStatus -> string

module ContestsIdPutRequestStatus : sig
  type nonrec t = contestsIdPutRequestStatus
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type contestsIdPutRequest = {
  title: string option;
  description: string option;
  start_time: string option;
  end_time: string option;
  status: contestsIdPutRequestStatus option;
}

val create_contestsIdPutRequest : ?title:string -> ?description:string -> ?start_time:string -> ?end_time:string -> ?status:contestsIdPutRequestStatus -> unit -> contestsIdPutRequest
val contestsIdPutRequest_of_yojson : Yojson.Safe.t -> contestsIdPutRequest
val yojson_of_contestsIdPutRequest : contestsIdPutRequest -> Yojson.Safe.t
val contestsIdPutRequest_of_json : string -> contestsIdPutRequest
val json_of_contestsIdPutRequest : contestsIdPutRequest -> string

module ContestsIdPutRequest : sig
  type nonrec t = contestsIdPutRequest
  val create : ?title:string -> ?description:string -> ?start_time:string -> ?end_time:string -> ?status:contestsIdPutRequestStatus -> unit -> t
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

type contestsGetResponse2 = contest list

val contestsGetResponse2_of_yojson : Yojson.Safe.t -> contestsGetResponse2
val yojson_of_contestsGetResponse2 : contestsGetResponse2 -> Yojson.Safe.t
val contestsGetResponse2_of_json : string -> contestsGetResponse2
val json_of_contestsGetResponse2 : contestsGetResponse2 -> string

module ContestsGetResponse2 : sig
  type nonrec t = contestsGetResponse2
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type contestsContestsidProblemsGetResponse2 = problem list

val contestsContestsidProblemsGetResponse2_of_yojson : Yojson.Safe.t -> contestsContestsidProblemsGetResponse2
val yojson_of_contestsContestsidProblemsGetResponse2 : contestsContestsidProblemsGetResponse2 -> Yojson.Safe.t
val contestsContestsidProblemsGetResponse2_of_json : string -> contestsContestsidProblemsGetResponse2
val json_of_contestsContestsidProblemsGetResponse2 : contestsContestsidProblemsGetResponse2 -> string

module ContestsContestsidProblemsGetResponse2 : sig
  type nonrec t = contestsContestsidProblemsGetResponse2
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type contestsContestidSubmissionsGetResponse2 = submission list

val contestsContestidSubmissionsGetResponse2_of_yojson : Yojson.Safe.t -> contestsContestidSubmissionsGetResponse2
val yojson_of_contestsContestidSubmissionsGetResponse2 : contestsContestidSubmissionsGetResponse2 -> Yojson.Safe.t
val contestsContestidSubmissionsGetResponse2_of_json : string -> contestsContestidSubmissionsGetResponse2
val json_of_contestsContestidSubmissionsGetResponse2 : contestsContestidSubmissionsGetResponse2 -> string

module ContestsContestidSubmissionsGetResponse2 : sig
  type nonrec t = contestsContestidSubmissionsGetResponse2
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

type authLoginPostResponse41 = {
  error: string;
}

val create_authLoginPostResponse41 : error:string -> unit -> authLoginPostResponse41
val authLoginPostResponse41_of_yojson : Yojson.Safe.t -> authLoginPostResponse41
val yojson_of_authLoginPostResponse41 : authLoginPostResponse41 -> Yojson.Safe.t
val authLoginPostResponse41_of_json : string -> authLoginPostResponse41
val json_of_authLoginPostResponse41 : authLoginPostResponse41 -> string

module AuthLoginPostResponse41 : sig
  type nonrec t = authLoginPostResponse41
  val create : error:string -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type authLoginPostRequest = {
  username: string;
  password: string;
}

val create_authLoginPostRequest : username:string -> password:string -> unit -> authLoginPostRequest
val authLoginPostRequest_of_yojson : Yojson.Safe.t -> authLoginPostRequest
val yojson_of_authLoginPostRequest : authLoginPostRequest -> Yojson.Safe.t
val authLoginPostRequest_of_json : string -> authLoginPostRequest
val json_of_authLoginPostRequest : authLoginPostRequest -> string

module AuthLoginPostRequest : sig
  type nonrec t = authLoginPostRequest
  val create : username:string -> password:string -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

