(** Yodac Config *)
let getAdminYodacConfig = Admin_yodac.getConfig

let putAdminYodacConfig = Admin_yodac.putConfig

let getAdminYodacConfigHistory = Admin_yodac.getConfigHistory

(* Stats *)
let getAdminStats = Admin_stats.getStats

(* Users *)
let getAdminUsers = Admin_users.getUsers

let postAdminUsers = Admin_users.postUsers

let getAdminUsersId = Admin_users.getUsersId

let putAdminUsersId = Admin_users.putUsersId

let deleteAdminUsersId = Admin_users.deleteUsersId

(* Problems *)
let putAdminProblemsId = Problems.putProblemsId

let deleteAdminProblemsId = Problems.deleteProblemsId

(* Submissions *)
let postAdminSubmissionsIdReevaluate = Submissions.postSubmissionsIdReEvaluate
