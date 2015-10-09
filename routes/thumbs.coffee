_        = require('lodash')
express  = require('express')
Q        = require('q')
paginate = require('express-paginate')
accepts  = require('accepts')
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

getThumb = (data) ->
  where = {}
  if data.uniqueId
    where.uniqueId = data.uniqueId
  else
    where.serviceId = data.serviceId
    where.subjectId = data.subjectId
    where.rating = +data.rating
  Q Thumb.findOne(where).exec()

getOrCreateThumb = (data) ->
  data = filterFields data, editableFields
  Q Thumb.create(data)
  .catch (err) ->
    if err.code in [11000, 11001] # Duplicate thumb
      getThumb(data)
    else
      throw err

createFilter = ({caseFilter, agentFilter}) ->
  filter = {}

  if agentFilter
    filter['agent.name'] = new RegExp(agentFilter, 'i')

  if caseFilter

    # Enable comma-separated values + whitepsace ignoring
    caseFilter = (_.trim(i) for i in caseFilter.split(',')).join("|")

    re = new RegExp(caseFilter, 'i')
    filter['$or'] = [
      {'subjectId': re}
      {'user.name': re}
      {'user.email': re}
      {'user.company': re}
      {'user.ip': re}
      {'feedback': re}
    ]

  filter

PER_PAGE = 100

module.exports = (debug = false) ->

  router.use '/list', paginate.middleware(PER_PAGE, PER_PAGE)

  router.get '/list', (req, res, next) ->

    page = Math.max(1, req.param('page') or 1)
    caseFilter = req.param('case') or ''
    agentFilter = req.param('agent') or ''
    filter = createFilter {caseFilter, agentFilter}

    defList = Q.defer()
    Thumb.paginate filter, page, PER_PAGE, (err, pages, thumbs, count) ->
      return next(err) if err
      defList.resolve({pages, thumbs, count})
    , {sortBy: {createdAt: -1}}

    defCountPos = Q.defer()
    f = _.extend {rating: {$gt: 0}}, filter
    Thumb.count(f).exec (err, count) ->
      return next(err) if err
      defCountPos.resolve(count)

    defCountNeg = Q.defer()
    f = _.extend {rating: {$lt: 0}}, filter
    Thumb.count(f).exec (err, count) ->
      return next(err) if err
      defCountNeg.resolve(count)

    today = moment().startOf('day').utc().toDate()
    weekAgo = moment().clone().subtract(1, 'week').startOf('day').utc().toDate()

    defCountPosWeek = Q.defer()
    f = _.extend {rating: {$gt: 0}, createdAt: {$lt: today, $gte: weekAgo}}, filter
    Thumb.count(f).exec (err, count) ->
      return next(err) if err
      defCountPosWeek.resolve(count)

    defCountNegWeek = Q.defer()
    f = _.extend {rating: {$lt: 0}, createdAt: {$lt: today, $gte: weekAgo}}, filter
    Thumb.count(f).exec (err, count) ->
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
        caseFilter
        agentFilter
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
        truncateFeedback: (feedback) ->
          if feedback?.length > 80
            words = feedback.replace(/\s+/g, ' ').split(' ')
            truncated = ""
            truncated += " #{w}" for w in words when truncated.length < 70
            feedback = truncated.substr(0, 80) + '...'
          feedback
      }

  router.post '/', (req, res, next) ->
    data = _.extend {}, req.body, {'user.ip': req.ip}
    getOrCreateThumb(data)
    .then (thumb) ->
      switch accepts(req).type(['json', 'html'])
        when 'html'
          res.render('vote', {thumb})
        when 'json'
          res.send({id: thumb.id})
        else
          res.status(200).end()
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
    getOrCreateThumb(data)
    .then (thumb) ->
      switch accepts(req).type(['json', 'html'])
        when 'html'
          res.render('vote', {thumb})
        when 'json'
          res.send({id: thumb.id})
        else
          res.status(200).end()
    .catch (err) ->
      if err.name is "ValidationError"
        message = _.map(err.errors, (i) -> i.message).join(' ')
        res.status(400).send("Validation errors: #{message}")
      else
        next(err)

  router.post '/feedback', (req, res, next) ->
    feedback = (req.body.feedback or "").trim()
    res.render 'thankyou' if not feedback
    Q Thumb.update({_id: req.body.id}, {feedback: req.body.feedback}).exec()
    .then ->
      switch accepts(req).type(['json', 'html'])
        when 'html'
          res.render('thankyou')
        when 'json'
          res.send({id: req.body.id})
        else
          res.status(200).end()

    .catch next
