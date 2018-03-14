const Q = require('q')

module.exports = {
  connected: false,
  ifConnected () {
    return Q.Promise((resolve, reject, notify) => {
      if (this.connected) {
        resolve()
      } else {
        console.log('A10, I am not connected')
        reject()
      }
    })
  }
}
