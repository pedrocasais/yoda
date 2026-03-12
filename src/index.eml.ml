let html param request= 
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Document</title>
   <link rel="icon" type="image/x-icon" href="./resources/ocaml-icon.ico">
</head>
<body>
  boas
  <h1>Hello, <%s param %>!</h1>
  <br>
  <form action="/auth/register" method="post">
      <%s! Dream.csrf_tag request %> 
  <input type="email" name="email" placeholder="Enter email" required>
  <button type="submit">Login</button>
</form>
</body>
</html>