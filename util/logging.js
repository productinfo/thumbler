const process = require('process')
const _ = require('lodash')

module.exports = {
  setEnv () {
    // if no DEBUG, try to parse it from --debug=... argument
    if (!process.env.DEBUG) {
      const debugFlag = _.find(process.argv, i => i.match(/^--debug/))
      if (debugFlag) {
        const namespaces = debugFlag.split('=')[1]
        process.env.DEBUG = namespaces || '*'
      }
    }
  },

  initialize () {
    this.setEnv()

    const debug = require('debug')
    debug.colors = [2, 6, 3, 1, 5, 4]

    this.log = debug('thumbler:log')
    this.info = debug('thumbler:info')
    this.warn = debug('thumbler:warn')
    this.warn.log = console.warn.bind(console)
    this.error = debug('thumbler:error')
    this.error.log = console.error.bind(console)

    this.log('  Rainbow  !')
    this.info(' Rainbow  !')
    this.warn(' Rainbow  !')
    this.error('Restarting')
  }
}
