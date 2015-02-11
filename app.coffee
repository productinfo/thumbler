process = require('process')
_ = require('lodash')

logging = require('./util/logging')
logging.initialize()

express = require("express")
path = require("path")
favicon = require("serve-favicon")
logger = require("morgan")
cookieParser = require("cookie-parser")
bodyParser = require("body-parser")
thumbsRouter = require("./routes/thumbs")
compression = require('compression')
Q = require('q')
cons = require('consolidate')
eco = require('eco')
mongoose = require('mongoose')

app = express()

# view engine setup
app.set "views", path.join(__dirname, "views")
app.engine('eco', cons.eco)
app.set "view engine", "eco"

app.use(favicon(__dirname + '/public/favicon.ico'));
app.enable('trust proxy')
app.use logger("dev")
app.use bodyParser.json()
app.use(compression())
app.use bodyParser.urlencoded(extended: false)
app.use cookieParser()
app.use express.static(path.join(__dirname, "public"))

app.get '/sanity', (req, res) -> res.status(404).send("Sanity not found")
app.get '/status', (req, res) -> res.status(200).end()

app.use "/thumbs", thumbsRouter(app.get("env") is "development")

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
    logging.error(err.stack)
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

try
  dbUrl = process.env.DB_URL
  dbUrl = require('./db_config.json').url if not dbUrl
catch
  logging.error "Please specify the DB connection URL either via DB_URL env variable or in db_config.json"

module.exports =
  app: app
  run: (port = 7501) ->
    Q()
    .then ->
      logging.log('Init #3: Running server')
      # Run server
      mongoose.connect dbUrl, (err, db) ->
        logging.error('DB connection error', err) if err
        app.set 'port', port
        server = app.listen app.get('port'), ->
          logging.info('Thumbler server listening on port ' + server.address().port)
    .fail (error) ->
      logging.error("app run error:", error)

if not module.parent
  q = Q()
  q = q.then -> module.exports.run()
