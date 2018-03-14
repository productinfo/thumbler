const _        = require('lodash');
const express  = require('express');
const router   = express.Router();
const Thumb    = require('../model/thumb.coffee');
const dbState  = require('../util/db_state.coffee');

module.exports = function(debug = false) {
  return router.get('/', (req, res) =>
    dbState.ifConnected().then(() => Thumb.findOne({}, '_id').exec()).then(() => res.status(200).end()).catch(() => res.status(500).send("DB connection failed").end())
  );
};
