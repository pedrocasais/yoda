open Tyxml.Html



let users ~users =
  html
    (head
       (title (txt "Document"))
       [
         meta ~a:[a_charset "UTF-8"] ();
         meta ~a:[a_name "viewport"; a_content "width=device-width, initial-scale=1.0"] ();
         link ~rel:[`Icon] ~href:"./resources/ocaml-icon.ico" ();
       ])
    (body [
       txt "boas";
       br ();
       ul (List.map (fun x -> li [txt x]) users);
       br ();
     ])

let usersbyID ~users2 =
  html
    (head
       (title (txt "Document"))
       [
         meta ~a:[a_charset "UTF-8"] ();
         meta ~a:[a_name "viewport"; a_content "width=device-width, initial-scale=1.0"] ();
         link ~rel:[`Icon] ~href:"./resources/ocaml-icon.ico" ();
       ])
    (body [
       txt "boas";
       br ();
       ul (List.map (fun (a,b) -> li [ txt a; txt ":"; txt b ]) users2);
       br ();
     ])
