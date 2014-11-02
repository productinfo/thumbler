process = require('process')
_ = require('lodash')

module.exports =
  initialize: ->

    if not process.env.DEBUG
      debugFlag = _.find(process.argv, (i) -> i.match(/^--debug/))
      if debugFlag
        namespaces = debugFlag.split('=')[1]
        process.env.DEBUG = namespaces or '*'

    debug = require('debug')
    debug.colors = [2, 6, 3, 1, 5, 4]

    @log = debug('thumbler:log')
    @info = debug('thumbler:info')
    @warn = debug('thumbler:warn')
    @warn.log = console.warn.bind(console)
    @error = debug('thumbler:error')
    @error.log = console.error.bind(console)

    @log('  Rainbow  !')
    @info(' Rainbow  !')
    @warn(' Rainbow  !')
    @error('Restarting')