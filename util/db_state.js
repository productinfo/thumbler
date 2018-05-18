module.exports = {
  connected: false,
  ifConnected () {
    return new Promise((resolve, reject) => {
      if (this.connected) {
        resolve()
      } else {
        console.log('A10, I am not connected')
        // eslint-disable-next-line prefer-promise-reject-errors
        reject()
      }
    })
  }
}
