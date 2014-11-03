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
]

createThumb = (data) ->
  data = _.pick data, editableFields
  Q Thumb.create(data)

router.get '/', (req, res) ->
  Thumb.find().sort('-createdAt').limit(10).exec (err, thumbs) ->
    res.render 'index', {thumbs}

router.post '/', (req, res, next) ->
  createThumb(req.body)
  .then -> res.status(200).end()
  .catch (err) ->
    if err.code in [11000, 11001]
      res.status(400).send("Duplicate thumb")
    else
      next(err)

router.get '/vote', (req, res, next) ->
  createThumb(req.params)
  .then -> res.status(200).end()
  .catch (err) ->
    if err.code in [11000, 11001]
      res.status(400).send("Duplicate thumb")
    else
      next(err)

module.exports = router
