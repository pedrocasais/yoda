(* Auto-generated from "openapi.atd" by atdml. *)

type yodacLanguageConfig = {
  language: string;
  ext: string;
  image: string;
  tag: string;
  compile: string option option;
  run: string;
}

val create_yodacLanguageConfig : language:string -> ext:string -> image:string -> tag:string -> ?compile:string option -> run:string -> unit -> yodacLanguageConfig
val yodacLanguageConfig_of_yojson : Yojson.Safe.t -> yodacLanguageConfig
val yojson_of_yodacLanguageConfig : yodacLanguageConfig -> Yojson.Safe.t
val yodacLanguageConfig_of_json : string -> yodacLanguageConfig
val json_of_yodacLanguageConfig : yodacLanguageConfig -> string

module YodacLanguageConfig : sig
  type nonrec t = yodacLanguageConfig
  val create : language:string -> ext:string -> image:string -> tag:string -> ?compile:string option -> run:string -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type yodacLanguagesConfig = yodacLanguageConfig list

val yodacLanguagesConfig_of_yojson : Yojson.Safe.t -> yodacLanguagesConfig
val yojson_of_yodacLanguagesConfig : yodacLanguagesConfig -> Yojson.Safe.t
val yodacLanguagesConfig_of_json : string -> yodacLanguagesConfig
val json_of_yodacLanguagesConfig : yodacLanguagesConfig -> string

module YodacLanguagesConfig : sig
  type nonrec t = yodacLanguagesConfig
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type yodacConfigPutRequest = {
  config: yodacLanguagesConfig;
}

val create_yodacConfigPutRequest : config:yodacLanguagesConfig -> unit -> yodacConfigPutRequest
val yodacConfigPutRequest_of_yojson : Yojson.Safe.t -> yodacConfigPutRequest
val yojson_of_yodacConfigPutRequest : yodacConfigPutRequest -> Yojson.Safe.t
val yodacConfigPutRequest_of_json : string -> yodacConfigPutRequest
val json_of_yodacConfigPutRequest : yodacConfigPutRequest -> string

module YodacConfigPutRequest : sig
  type nonrec t = yodacConfigPutRequest
  val create : config:yodacLanguagesConfig -> unit -> t
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

type yodacConfigHistoryEntry = {
  version: int;
  timestamp: string;
  changed_by: string;
  action: string;
  previous_config: json_ option option;
  new_config: yodacLanguagesConfig;
}

val create_yodacConfigHistoryEntry : version:int -> timestamp:string -> changed_by:string -> action:string -> ?previous_config:json_ option -> new_config:yodacLanguagesConfig -> unit -> yodacConfigHistoryEntry
val yodacConfigHistoryEntry_of_yojson : Yojson.Safe.t -> yodacConfigHistoryEntry
val yojson_of_yodacConfigHistoryEntry : yodacConfigHistoryEntry -> Yojson.Safe.t
val yodacConfigHistoryEntry_of_json : string -> yodacConfigHistoryEntry
val json_of_yodacConfigHistoryEntry : yodacConfigHistoryEntry -> string

module YodacConfigHistoryEntry : sig
  type nonrec t = yodacConfigHistoryEntry
  val create : version:int -> timestamp:string -> changed_by:string -> action:string -> ?previous_config:json_ option -> new_config:yodacLanguagesConfig -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type yodacConfigHistoryGetResponse = yodacConfigHistoryEntry list

val yodacConfigHistoryGetResponse_of_yojson : Yojson.Safe.t -> yodacConfigHistoryGetResponse
val yojson_of_yodacConfigHistoryGetResponse : yodacConfigHistoryGetResponse -> Yojson.Safe.t
val yodacConfigHistoryGetResponse_of_json : string -> yodacConfigHistoryGetResponse
val json_of_yodacConfigHistoryGetResponse : yodacConfigHistoryGetResponse -> string

module YodacConfigHistoryGetResponse : sig
  type nonrec t = yodacConfigHistoryGetResponse
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type yodacConfigGetResponse = {
  config: yodacLanguagesConfig;
  version: int;
  updated_at: string;
  updated_by: string;
}

val create_yodacConfigGetResponse : config:yodacLanguagesConfig -> version:int -> updated_at:string -> updated_by:string -> unit -> yodacConfigGetResponse
val yodacConfigGetResponse_of_yojson : Yojson.Safe.t -> yodacConfigGetResponse
val yojson_of_yodacConfigGetResponse : yodacConfigGetResponse -> Yojson.Safe.t
val yodacConfigGetResponse_of_json : string -> yodacConfigGetResponse
val json_of_yodacConfigGetResponse : yodacConfigGetResponse -> string

module YodacConfigGetResponse : sig
  type nonrec t = yodacConfigGetResponse
  val create : config:yodacLanguagesConfig -> version:int -> updated_at:string -> updated_by:string -> unit -> t
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

type userGroup = string list

val userGroup_of_yojson : Yojson.Safe.t -> userGroup
val yojson_of_userGroup : userGroup -> Yojson.Safe.t
val userGroup_of_json : string -> userGroup
val json_of_userGroup : userGroup -> string

module UserGroup : sig
  type nonrec t = userGroup
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type userUpdateRequest = {
  username: string option;
  role: userRole option;
  groups: userGroup option;
}

val create_userUpdateRequest : ?username:string -> ?role:userRole -> ?groups:userGroup -> unit -> userUpdateRequest
val userUpdateRequest_of_yojson : Yojson.Safe.t -> userUpdateRequest
val yojson_of_userUpdateRequest : userUpdateRequest -> Yojson.Safe.t
val userUpdateRequest_of_json : string -> userUpdateRequest
val json_of_userUpdateRequest : userUpdateRequest -> string

module UserUpdateRequest : sig
  type nonrec t = userUpdateRequest
  val create : ?username:string -> ?role:userRole -> ?groups:userGroup -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type userCreateRequest = {
  username: string;
  password: string;
  role: userRole;
  groups: userGroup option;
}

val create_userCreateRequest : username:string -> password:string -> role:userRole -> ?groups:userGroup -> unit -> userCreateRequest
val userCreateRequest_of_yojson : Yojson.Safe.t -> userCreateRequest
val yojson_of_userCreateRequest : userCreateRequest -> Yojson.Safe.t
val userCreateRequest_of_json : string -> userCreateRequest
val json_of_userCreateRequest : userCreateRequest -> string

module UserCreateRequest : sig
  type nonrec t = userCreateRequest
  val create : username:string -> password:string -> role:userRole -> ?groups:userGroup -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type user = {
  id: int;
  username: string;
  role: userRole;
  groups: userGroup;
  created_at: string;
  last_seen_at: string option;
}

val create_user : id:int -> username:string -> role:userRole -> groups:userGroup -> created_at:string -> ?last_seen_at:string -> unit -> user
val user_of_yojson : Yojson.Safe.t -> user
val yojson_of_user : user -> Yojson.Safe.t
val user_of_json : string -> user
val json_of_user : user -> string

module User : sig
  type nonrec t = user
  val create : id:int -> username:string -> role:userRole -> groups:userGroup -> created_at:string -> ?last_seen_at:string -> unit -> t
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
  problem_id: int;
  language: string option;
  status: string;
  score: int;
  time_ms: int;
  memory_kb: int;
  details: submissionDetails list;
}

val create_submission : id:int -> problem_id:int -> ?language:string -> status:string -> score:int -> time_ms:int -> memory_kb:int -> details:submissionDetails list -> unit -> submission
val submission_of_yojson : Yojson.Safe.t -> submission
val yojson_of_submission : submission -> Yojson.Safe.t
val submission_of_json : string -> submission
val json_of_submission : submission -> string

module Submission : sig
  type nonrec t = submission
  val create : id:int -> problem_id:int -> ?language:string -> status:string -> score:int -> time_ms:int -> memory_kb:int -> details:submissionDetails list -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type solutionSource_artifacts = {
  filename: string;  (** The name of the source file *)
  content: string;  (** The content of the source file *)
}

val create_solutionSource_artifacts : filename:string -> content:string -> unit -> solutionSource_artifacts
val solutionSource_artifacts_of_yojson : Yojson.Safe.t -> solutionSource_artifacts
val yojson_of_solutionSource_artifacts : solutionSource_artifacts -> Yojson.Safe.t
val solutionSource_artifacts_of_json : string -> solutionSource_artifacts
val json_of_solutionSource_artifacts : solutionSource_artifacts -> string

module SolutionSource_artifacts : sig
  type nonrec t = solutionSource_artifacts
  val create : filename:string -> content:string -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type solution = {
  problem_id: int;
  language: string;
  source_artifacts: solutionSource_artifacts list;
}

val create_solution : problem_id:int -> language:string -> source_artifacts:solutionSource_artifacts list -> unit -> solution
val solution_of_yojson : Yojson.Safe.t -> solution
val yojson_of_solution : solution -> Yojson.Safe.t
val solution_of_json : string -> solution
val json_of_solution : solution -> string

module Solution : sig
  type nonrec t = solution
  val create : problem_id:int -> language:string -> source_artifacts:solutionSource_artifacts list -> unit -> t
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
  id: int option;
  code: string;
  title: string;
  time_limit_ms: int;
  memory_limit_mb: int;
  description: string;
  input_spec: string;
  output_spec: string;
}

val create_problem : ?id:int -> code:string -> title:string -> time_limit_ms:int -> memory_limit_mb:int -> description:string -> input_spec:string -> output_spec:string -> unit -> problem
val problem_of_yojson : Yojson.Safe.t -> problem
val yojson_of_problem : problem -> Yojson.Safe.t
val problem_of_json : string -> problem
val json_of_problem : problem -> string

module Problem : sig
  type nonrec t = problem
  val create : ?id:int -> code:string -> title:string -> time_limit_ms:int -> memory_limit_mb:int -> description:string -> input_spec:string -> output_spec:string -> unit -> t
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

type errorResponse = {
  error: string;
}

val create_errorResponse : error:string -> unit -> errorResponse
val errorResponse_of_yojson : Yojson.Safe.t -> errorResponse
val yojson_of_errorResponse : errorResponse -> Yojson.Safe.t
val errorResponse_of_json : string -> errorResponse
val json_of_errorResponse : errorResponse -> string

module ErrorResponse : sig
  type nonrec t = errorResponse
  val create : error:string -> unit -> t
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

type authRegisterPostRequest = {
  username: string;
  password: string;
  role: userRole;
}

val create_authRegisterPostRequest : username:string -> password:string -> role:userRole -> unit -> authRegisterPostRequest
val authRegisterPostRequest_of_yojson : Yojson.Safe.t -> authRegisterPostRequest
val yojson_of_authRegisterPostRequest : authRegisterPostRequest -> Yojson.Safe.t
val authRegisterPostRequest_of_json : string -> authRegisterPostRequest
val json_of_authRegisterPostRequest : authRegisterPostRequest -> string

module AuthRegisterPostRequest : sig
  type nonrec t = authRegisterPostRequest
  val create : username:string -> password:string -> role:userRole -> unit -> t
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

type adminYodacStats = {
  queued_jobs_total: int option;
  queued_jobs_per_minute: int;
  processed_jobs_total: int;
  processed_jobs_per_minute: int;
}

val create_adminYodacStats : ?queued_jobs_total:int -> queued_jobs_per_minute:int -> processed_jobs_total:int -> processed_jobs_per_minute:int -> unit -> adminYodacStats
val adminYodacStats_of_yojson : Yojson.Safe.t -> adminYodacStats
val yojson_of_adminYodacStats : adminYodacStats -> Yojson.Safe.t
val adminYodacStats_of_json : string -> adminYodacStats
val json_of_adminYodacStats : adminYodacStats -> string

module AdminYodacStats : sig
  type nonrec t = adminYodacStats
  val create : ?queued_jobs_total:int -> queued_jobs_per_minute:int -> processed_jobs_total:int -> processed_jobs_per_minute:int -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type adminYodabStats = {
  yodab_requests_total: int;
  yodab_requests_per_minute: int;
  submissions_total: int;
  submissions_per_minute: int;
}

val create_adminYodabStats : yodab_requests_total:int -> yodab_requests_per_minute:int -> submissions_total:int -> submissions_per_minute:int -> unit -> adminYodabStats
val adminYodabStats_of_yojson : Yojson.Safe.t -> adminYodabStats
val yojson_of_adminYodabStats : adminYodabStats -> Yojson.Safe.t
val adminYodabStats_of_json : string -> adminYodabStats
val json_of_adminYodabStats : adminYodabStats -> string

module AdminYodabStats : sig
  type nonrec t = adminYodabStats
  val create : yodab_requests_total:int -> yodab_requests_per_minute:int -> submissions_total:int -> submissions_per_minute:int -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type adminUsersGetResponse2 = user list

val adminUsersGetResponse2_of_yojson : Yojson.Safe.t -> adminUsersGetResponse2
val yojson_of_adminUsersGetResponse2 : adminUsersGetResponse2 -> Yojson.Safe.t
val adminUsersGetResponse2_of_json : string -> adminUsersGetResponse2
val json_of_adminUsersGetResponse2 : adminUsersGetResponse2 -> string

module AdminUsersGetResponse2 : sig
  type nonrec t = adminUsersGetResponse2
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

type adminStatsResponse = {
  api_version: string;
  yoda_version: string;
  contributors: string list;
  yodab: adminYodabStats;
  yodac: adminYodacStats;
}

val create_adminStatsResponse : api_version:string -> yoda_version:string -> contributors:string list -> yodab:adminYodabStats -> yodac:adminYodacStats -> unit -> adminStatsResponse
val adminStatsResponse_of_yojson : Yojson.Safe.t -> adminStatsResponse
val yojson_of_adminStatsResponse : adminStatsResponse -> Yojson.Safe.t
val adminStatsResponse_of_json : string -> adminStatsResponse
val json_of_adminStatsResponse : adminStatsResponse -> string

module AdminStatsResponse : sig
  type nonrec t = adminStatsResponse
  val create : api_version:string -> yoda_version:string -> contributors:string list -> yodab:adminYodabStats -> yodac:adminYodacStats -> unit -> t
  val of_yojson : Yojson.Safe.t -> t
  val to_yojson : t -> Yojson.Safe.t
  val of_json : string -> t
  val to_json : t -> string
end

