open Lwt.Infix
open Redis_lwt

let getContestsIdScoreboard _request = failwith "getContestsIdScoreboard"

let getContestsContestIdSubmissions _request =
  failwith "getContestsContestIdSubmissions"

let postContestsContestsIdProblems _request =
  failwith "postContestsContestsIdProblems"

let getContestsContestsIdProblems _request =
  failwith "getContestsContestsIdProblems"

let deleteContestsId request =
  let id = Dream.param request "id" in
  Lwt_pool.use Db.pool(fun conn -> Client.del conn [("contest:"^id)]) >>= function 
  | 0 -> Dream.html "nao existe"
  | 1 -> Dream.html "deleted"
  | _ -> Dream.html "errpr"

let putContestsId _request = failwith "putContestsId"

let getContestsId request =
  let id = Dream.param request "id" in
  Lwt_pool.use Db.pool (fun conn -> Client.hgetall conn ("contest:" ^ id))
  >>= function
  | [] -> Dream.html "nao existe"
  | x ->
      Dream.html (String.concat "" (List.map (fun (k, v) -> k ^ ":" ^ v) x))

let postContests _request = failwith "postContests"

let getContests _request = 
  Lwt_pool.use Db.pool (fun conn -> Client.scan conn 0 ~pattern:"contest:*")
  >>= function
  | _,[] -> Dream.html "nao existe"
  | _,x ->
      Dream.html (String.concat "" x)