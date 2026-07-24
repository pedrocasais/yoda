]
|> Dream.memory_sessions ~lifetime:(60.0 *. 60.0)
|> Dream.logger
in

Dream.run
  ~interface:"0.0.0.0"
  ~port:8001
  app
