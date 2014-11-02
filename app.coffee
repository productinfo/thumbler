process = require('process')
_ = require('lodash')

logging = require('./utils/logging')
logging.initialize()

express = require("express")
path = require("path")
favicon = require("serve-favicon")
logger = require("morgan")
cookieParser = require("cookie-parser")
bodyParser = require("body-parser")
router = require("./routes/index")
compression = require('compression')
Q = require('q')
cons =require('consolidate')
eco = require('eco')

app = express()

# view engine setup
app.set "views", path.join(__dirname, "views")
app.engine('eco', cons.eco)
app.set "view engine", "eco"

# uncomment after placing your favicon in /public
# app.use(favicon(__dirname + '/public/favicon.ico'));
app.use logger("dev")
app.use bodyParser.json()
app.use(compression())
app.use bodyParser.urlencoded(extended: false)
app.use cookieParser()
app.use express.static(path.join(__dirname, "public"))

app.get '/sanity', (req, res) -> res.status(404).send("Sanity not found")
app.get '/status', (req, res) -> res.status(200).end()

app.use "/", router

# catch 404 and forward to error handler
app.use (req, res, next) ->
  err = new Error("Not Found")
  err.status = 404
  next err


# error handlers

# development error handler
# will print stacktrace
if app.get("env") is "development"
  app.use (err, req, res, next) ->
    res.status err.status or 500
    res.render "error",
      message: err.message
      error: err


# production error handler
# no stacktraces leaked to user
app.use (err, req, res, next) ->
  res.status err.status or 500
  res.render "error",
    message: err.message
    error: {}

module.exports =
  app: app
  resetDB: ->
    Q()
    .then ->
      logging.log('Init #1: Resetting DB')
      # model.sequelize.sync(force: true)
    .then ->
      logging.log('Init #2: Loading fixtures')
      # Load dev-hacking fixtures
      # require('./model/fixtures')(model)
    .fail (error) ->
      logging.error("app.resetDB error:", error)
  run: (port = 7501) ->
    Q()
    .then ->
      logging.log('Init #3: Running server')
      # Run server
      app.set 'port', port
      server = app.listen app.get('port'), ->
        logging.info('Thumbler server listening on port ' + server.address().port)
    .fail (error) ->
      logging.error("app run error:", error)

if not module.parent
  q = Q()
  unless '--no-rebuild' in process.argv
    q = q.then -> module.exports.resetDB()
  q = q.then -> module.exports.run()
