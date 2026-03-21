(* Auto-generated from "types.atd" *)
[@@@ocaml.warning "-27-32-33-35-39"]

type userRole = [ `User | `Judge | `Admin ]

type user = { id: int; username: string; role: userRole; created_at: string }

type testCase = { input: string; output: string; is_sample: bool }

type submissionDetails = { testcase_id: int; status: string; time_ms: int }

type submission = {
  id: int;
  status: string;
  score: int;
  time_ms: int;
  memory_kb: int;
  details: submissionDetails list
}

type solution = {
  contest_id: int;
  problem_id: int;
  language: string;
  source_code: string
}

type json = Yojson.Basic.t

type scoreboardEntry = {
  team: string;
  solved: int;
  penalty: int;
  problems: json
}

type problem = {
  code: string;
  title: string;
  time_limit_ms: int;
  memory_limit_mb: int;
  description: string;
  input_spec: string;
  output_spec: string
}

type int64 = Int64.t

type contestStatus = [ `Upcoming | `Running | `Finished ]

type contest = {
  id: int;
  title: string;
  description: string option;
  start_time: string;
  end_time: string;
  status: contestStatus
}

type authToken = { token: string; user: user }