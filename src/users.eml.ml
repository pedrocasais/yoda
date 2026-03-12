let html _param _request _users = 
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Document</title>
   <link rel="icon" type="image/x-icon" href="./resources/ocaml-icon.ico">
</head>
<body>
  boas

  <br>
<ul>
    % List.iter (fun x -> 
      <li>
      % x 
      </li>
    % ) _users; 
  </ul>
  <br>

  <form action="/auth/login" method="post">
      % Dream.csrf_tag request  
  <input type="email" name="email" placeholder="Enter email" required>
  <button type="submit">Login</button>
</form>
</body>
</html>

let html2 param _request users2 = 
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Document</title>
   <link rel="icon" type="image/x-icon" href="./resources/ocaml-icon.ico">
</head>
<body>
  boas
  <br>
<ul>
 % List.iter (fun x -> 
      <li>
      % x 
      </li>
    % ) users2; 
  </ul>
  <br>

</body>
</html>