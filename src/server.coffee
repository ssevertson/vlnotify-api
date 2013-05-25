app = require './app'

app.init (err) ->
  if err
    app.log.error 'Error during initialization: %j', err
    throw err

  app.createServer()

  port = app.config.get('app:port')
  for host in app.config.get 'app:hosts'
    do (host) ->
      app.listen port, host, ->
        app.log.info 'Listening: http://%s:%d/', host, port
