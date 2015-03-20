_        = require('lodash')
express  = require('express')
router   = express.Router()
Thumb    = require('../model/thumb.coffee')

module.exports = (debug = false) ->
  router.get '/', (req, res) ->
    Thumb.findOne (err, thumb) ->
      res.status(500) if !!err
      res.status(200).end()

