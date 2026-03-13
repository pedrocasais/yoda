open Tyxml.Html

let detailUserPage _request _users3 =
  html
    (head
       (title (txt "User Detail"))
       [
         meta ~a:[a_charset "UTF-8"] ();
         meta ~a:[a_name "viewport"; a_content "width=device-width, initial-scale=1.0"] ();
       ])
    (body
       [
         h1 [txt "User Details"];
         br ();
         (* User detail list *)
         ul (
           List.map (fun (k, v) ->
             li [
               strong [txt k];
               txt ": ";
               txt v
             ]
           ) _users3
         );
         br ();
       ])
