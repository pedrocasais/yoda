(** Match test cases based on their content. *)

(** Split a string into a list of tokens, removing whitespace, tabs, and newlines. *)
let tokens_of_string (value : string) : string list =
  let is_whitespace = function
    | ' ' | '\t' | '\r' | '\n' -> true
    | _ -> false
  in
  value
  |> String.map (fun c -> if is_whitespace c then ' ' else c)
  |> String.split_on_char ' '
  |> List.filter (fun token -> token <> "")

(** Calculate the distance between two lists of tokens. It uses the Levenshtein distance algorithm. *)
let distance_to_any_token_sublist (needle : string list)
    (haystack : string list) : int =
  let needle = Array.of_list needle in
  let haystack = Array.of_list haystack in
  let needle_length = Array.length needle in
  let haystack_length = Array.length haystack in
  if needle_length = 0 then 0
  else if haystack_length = 0 then needle_length
  else
    (* A zero first row allows the matching sublist to start at any position
       in the haystack. *)
    let previous = Array.make (haystack_length + 1) 0 in
    for i = 1 to needle_length do
      let current = Array.make (haystack_length + 1) 0 in
      (* Delete the first [i] tokens from the needle. *)
      current.(0) <- i ;
      for j = 1 to haystack_length do
        let substitution_cost =
          if String.equal needle.(i - 1) haystack.(j - 1) then 0 else 1
        in
        let deletion = previous.(j) + 1 in
        let insertion = current.(j - 1) + 1 in
        let substitution = previous.(j - 1) + substitution_cost in
        current.(j) <- min deletion (min insertion substitution)
      done ;
      Array.blit current 0 previous 0 (haystack_length + 1)
    done ;
    let result = ref previous.(1) in
    for j = 2 to haystack_length do
      result := min !result previous.(j)
    done ;
    !result

(** Calculate the similarity between two lists of tokens. *)
let similarity (needle : string list) (distance : int) : float =
  match needle with
  | [] -> 1.0
  | _ -> max 0.0 (1.0 -. (float distance /. float (List.length needle)))
