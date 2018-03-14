Q = require('q')

module.exports =
  connected: false
  ifConnected: ->
    Q.Promise (resolve, reject, notify) =>
      if @connected
        resolve()
      else
        console.log('A10, I am not connected')
        reject()

