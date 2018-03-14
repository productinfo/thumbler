const process = require('process')
const _ = require('lodash')

const logging = require('./util/logging')
logging.initialize()

const express = require('express')
const cors = require('cors')
const path = require('path')
const favicon = require('serve-favicon')
const logger = require('morgan')
const cookieParser = require('cookie-parser')
const bodyParser = require('body-parser')
const thumbsRouter = require('./routes/thumbs')
const statusRouter = require('./routes/status')
const compression = require('compression')
const Q = require('q')
const cons = require('consolidate')
const eco = require('eco')
const mongoose = require('mongoose')
const dbState = require('./util/db_state')

let hooks
try {
  hooks = require('./local_config/hooks')
} catch (e) {
  hooks = {}
}

const app = express()

// view engine setup
app.set('views', path.join(__dirname, 'views'))
app.engine('eco', cons.eco)
app.set('view engine', 'eco')

app.use(favicon(__dirname + '/public/favicon.ico'))
app.enable('trust proxy')
app.use(logger('dev'))
app.use(bodyParser.json())
app.use(compression())
app.use(bodyParser.urlencoded({ extended: false }))
app.use(cookieParser())
app.use(express.static(path.join(__dirname, 'public')))

app.use(
  cors({
    origin: (origin, cb) =>
      cb(null, _.result(hooks, 'corsWhitelist', []).indexOf(origin) > -1)
  })
)

app.get('/sanity', (req, res) => res.status(404).send('Sanity not found'))
app.use('/status', statusRouter(app.get('env') === 'development'))

app.use('/thumbs', thumbsRouter(app.get('env') === 'development'))

// catch 404 and forward to error handler
app.use((req, res, next) => {
  const err = new Error('Not Found')
  err.status = 404
  next(err)
})

// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
  app.use((err, req, res, next) => {
    logging.error(err.stack)
    res.status(err.status || 500)
    res.render('error', {
      message: err.message,
      error: err
    })
  })
}

// production error handler
// no stacktraces leaked to user
app.use((err, req, res, next) => {
  res.status(err.status || 500)
  res.render('error', {
    message: err.message,
    error: {}
  })
})

let dbUrl
try {
  dbUrl = process.env.DB_URL
  if (!dbUrl) {
    dbUrl = require('./db_config.json').url
  }
} catch (error) {
  logging.error(
    'Please specify the DB connection URL either via DB_URL env variable or in db_config.json'
  )
}

module.exports = {
  app,
  run(port = 7501) {
    return Q()
      .then(function() {
        logging.log('Init #3: Running server')
        app.set('port', port)
        // Run server
        var runServer = function() {
          mongoose.Promise = Q.Promise
          return mongoose.connect(
            dbUrl,
            { useMongoClient: true, autoReconnect: true, keepAlive: 1 },
            function(err) {
              let server
              if (err) {
                logging.error('DB connection error', err)
                logging.error('Trying again in 5s!')
                setTimeout(runServer, 5000)
                return
              }

              dbState.connected = true

              mongoose.connection.on('error', function(err) {
                logging.error('DB connection error', err)
                return (dbState.connected = false)
              })

              mongoose.connection.on('disconnected', function(err) {
                logging.error('DB connection dropped', err)
                return (dbState.connected = false)
              })

              mongoose.connection.on('connected', function() {
                logging.info('DB reconnected')
                return (dbState.connected = true)
              })

              return (server = app.listen(app.get('port'), () =>
                logging.info(
                  `Thumbler server listening on port ${server.address().port}`
                )
              ))
            }
          )
        }
        return runServer()
      })
      .fail(error => logging.error('app run error:', error))
  }
}

if (!module.parent) {
  let q = Q()
  q = q.then(() => module.exports.run())
}
