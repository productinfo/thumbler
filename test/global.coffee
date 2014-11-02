before (cb) ->
  thumbler = require('../app/app.coffee')
  global.app = thumbler.app
  thumbler.resetDB()
  .then ->
    thumbler.run()
  .then ->
    cb()

after (cb) ->
  cb()