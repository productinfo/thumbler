_ = require('lodash')
express = require('express')
Q = require('q')
router = express.Router()
Thumb = require('../model/thumb.coffee')

editableFields = [
  'rating'
  'serviceId'
  'uniqueId'
  'subjectId'
  'ip'
]

createThumb = (data) ->
  data = _.pick data, editableFields
  Q Thumb.create(data)


module.exports = (debug = false) ->

  if debug
    router.get '/', (req, res) ->
      Thumb.find().sort('-createdAt').limit(10).exec (err, thumbs) ->
        res.render 'index', {thumbs}

  router.post '/', (req, res, next) ->
    data = _.extend {}, req.body, {ip: req.ip}
    createThumb(data)
    .then -> res.status(200).end()
    .catch (err) ->
      if err.code in [11000, 11001]
        res.status(400).send("Duplicate thumb")
      else if err.name is "ValidationError"
        message = _.map(err.errors, (i) -> i.message).join(' ')
        res.status(400).send("Validation errors: #{message}")
      else
        next(err)

  router.get '/vote', (req, res, next) ->
    data = _.extend {}, req.query, {ip: req.ip}
    createThumb(data)
    .then (thumb) -> res.render 'vote', {thumb}
    .catch (err) ->
      if err.code in [11000, 11001]
        res.status(400).send("Duplicate thumb")
      else if err.name is "ValidationError"
        message = _.map(err.errors, (i) -> i.message).join(' ')
        res.status(400).send("Validation errors: #{message}")
      else
        next(err)
