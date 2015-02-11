_        = require('lodash')
express  = require('express')
Q        = require('q')
paginate = require('express-paginate')
router   = express.Router()
Thumb    = require('../model/thumb.coffee')
moment   = require('moment')

editableFields = [
  'rating'
  'serviceId'
  'uniqueId'
  'subjectId'
  'user.name'
  'user.email'
  'user.company'
  'user.ip'
  'agent.name'
]

filterFields = (data, fields) ->
  out = {}
  for k in fields
    continue if not data[k]?
    parts = k.split('.')
    lastPart = parts.pop()
    o = out
    for part in parts
      o[part] ?= {}
      o = o[part]
    o[lastPart] = data[k]
  out

createThumb = (data) ->
  data = filterFields data, editableFields
  Q Thumb.create(data)

PER_PAGE = 100

module.exports = (debug = false) ->

  router.use '/list', paginate.middleware(PER_PAGE, PER_PAGE)

  router.get '/list', (req, res, next) ->

    page = Math.max(1, req.param('page') or 1)

    defList = Q.defer()
    Thumb.paginate {}, page, PER_PAGE, (err, pages, thumbs, count) ->
      return next(err) if err
      defList.resolve({pages, thumbs, count})
    , {sortBy: {createdAt: -1}}

    defCountPos = Q.defer()
    Thumb.count({rating: {$gt: 0}}).exec (err, count) ->
      return next(err) if err
      defCountPos.resolve(count)

    defCountNeg = Q.defer()
    Thumb.count({rating: {$lt: 0}}).exec (err, count) ->
      return next(err) if err
      defCountNeg.resolve(count)

    today = moment().startOf('day').utc().toDate()
    weekAgo = moment().clone().subtract(1, 'week').startOf('day').utc().toDate()

    defCountPosWeek = Q.defer()
    Thumb.count({rating: {$gt: 0}, createdAt: {$lt: today, $gte: weekAgo}}).exec (err, count) ->
      return next(err) if err
      defCountPosWeek.resolve(count)

    defCountNegWeek = Q.defer()
    Thumb.count({rating: {$lt: 0}, createdAt: {$lt: today, $gte: weekAgo}}).exec (err, count) ->
      return next(err) if err
      defCountNegWeek.resolve(count)

    promises = [
      defList.promise
      defCountPos.promise
      defCountNeg.promise
      defCountPosWeek.promise
      defCountNegWeek.promise
    ]

    Q.all(promises).spread ({pages, thumbs, countAll}, countPos, countNeg, countPosWeek, countNegWeek) ->
      res.render 'index', {
        thumbs
        countAll
        countPos
        countNeg
        countPosWeek
        countNegWeek
        page: page
        totalPages: pages
        perPage: PER_PAGE
        getCaseId: (thumb) ->
          caseId = thumb.subjectId.split('_')
          result = "#{caseId[0]}-#{caseId[1]}"
          result += " (" + caseId[2].replace('T', ' ') + ")" if caseId[2]
          result
        getCaseLink: (thumb) ->
          caseId = thumb.subjectId.split('_')
          switch caseId[0]
            when 'desk'
              "https://toggl.desk.com/agent/case/#{caseId[1]}"
            else '#'
        formatDate: (date) ->
          moment(date).format("(ddd) DD-MM-YYYY HH:mm:ss Z")
      }

  router.post '/', (req, res, next) ->
    data = _.extend {}, req.body, {'user.ip': req.ip}
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
    data = _.extend {}, req.query, {'user.ip': req.ip}
    createThumb(data)
    .then (thumb) -> res.render 'vote', {thumb}
    .catch (err) ->
      if err.code in [11000, 11001]
        res.render 'vote', {thumb: null}
      else if err.name is "ValidationError"
        message = _.map(err.errors, (i) -> i.message).join(' ')
        res.status(400).send("Validation errors: #{message}")
      else
        next(err)
