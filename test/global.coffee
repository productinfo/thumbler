process = require('process')
before (cb) ->
  process.env.DEBUG = 'thumbler:*'
  thumbler = require('../app.coffee')
  global.app = thumbler.app
  thumbler.run()
  .then ->
    cb()

after (cb) ->
  cb()