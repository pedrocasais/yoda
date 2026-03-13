open Tyxml.Html

let csrf_tag request =
  [Unsafe.data (Dream.csrf_tag request)]

let index ~param ~request =
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
       h1 [txt "Hello,"];
       txt param;      (* dynamic text *)
       h1 [txt " !"];
       br ();
       (* Login form *)
       form ~a:[a_action "/auth/login"; a_method `Post] (
         csrf_tag request @ [
           input ~a:[a_input_type `Text; a_name "email"; a_placeholder "Enter email"; a_required ()] ();
           button ~a:[a_button_type `Submit] [txt "Login"];
         ]
       );
       (* Register form *)
       form ~a:[a_action "/auth/register"; a_method `Post] (
         csrf_tag request @ [
           input ~a:[a_input_type `Email; a_name "email"; a_placeholder "Enter email"; a_required ()] ();
           button ~a:[a_button_type `Submit] [txt "Register"];
         ]
       );
     ])
