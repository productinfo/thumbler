_        = require('lodash')
express  = require('express')
router   = express.Router()
Thumb    = require('../model/thumb.coffee')
dbState  = require('../util/db_state.coffee')

module.exports = (debug = false) ->
  router.get '/', (req, res) ->
    dbState.ifConnected().then ->
      Thumb.findOne({}, '_id').exec()
    .then ->
      res.status(200).end()
    .catch ->
      res.status(500).send("DB connection failed").end()

