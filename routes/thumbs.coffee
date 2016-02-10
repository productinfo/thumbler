_        = require('lodash')
express  = require('express')
Q        = require('q')
paginate = require('express-paginate')
accepts  = require('accepts')
router   = express.Router()
Thumb    = require('../model/thumb.coffee')
moment   = require('moment')

try
  hooks = require('../local_config/hooks')
catch e
  hooks = {}

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

createFilter = ({subjectFilter, agentFilter, dateFromFilter, dateToFilter, hasFeedbackFilter, notHandledFilter}) ->
  filter = {}

  if agentFilter
    # Enable comma-separated values + whitepsace ignoring
    agentFilter = (_.trim(i) for i in agentFilter.split(',')).join("|")
    filter['agent.name'] = new RegExp(agentFilter, 'i')

  if subjectFilter
    matchAnywhere = false
    if subjectFilter[0] is '*'
      subjectFilter = subjectFilter.substr(1)
      matchAnywhere = true
    re = new RegExp(subjectFilter, 'i')
    reBeginning = new RegExp('^' + subjectFilter, 'i')
    filter['$or'] = [
      {'subjectId': if matchAnywhere then re else reBeginning}
      {'user.name': re}
      {'user.email': re}
      {'user.company': re}
      {'user.ip': re}
      {'feedback': re}
    ]

  if dateFromFilter or dateToFilter

    d = dateFromFilter.split('/')
    if d.length is 3
      dateFrom = "#{d[2]}-#{_.padStart(d[1], 2, '0')}-#{d[0]}T00:00:00Z"

    d = dateToFilter.split('/')
    if d.length is 3
      dateTo = "#{d[2]}-#{_.padStart(d[1], 2, '0')}-#{d[0]}T23:59:59Z"

    if dateFrom or dateTo
      filter['createdAt'] = {}
      filter['createdAt']['$gte'] = new Date(dateFrom) if dateFrom
      filter['createdAt']['$lte'] = new Date(dateTo) if dateTo

  if hasFeedbackFilter
    filter['feedback'] = {
      '$exists': true
      '$ne': ''
    }

  if notHandledFilter
    filter['handled'] = {
      '$in': [false, null]
    }

  filter

PER_PAGE = 100

module.exports = (debug = false) ->

  router.use '/list', paginate.middleware(PER_PAGE, PER_PAGE)

  router.get '/list', (req, res, next) ->

    page = Math.max(1, req.param('page') or 1)
    subjectFilter = req.param('subject') or ''
    agentFilter = req.param('agent') or ''
    dateFromFilter = req.param('date_from') or ''
    dateToFilter = req.param('date_to') or ''
    hasFeedbackFilter = !!req.param('has_feedback') or false
    notHandledFilter = !!req.param('not_handled') or false
    filter = createFilter {subjectFilter, agentFilter, dateFromFilter, dateToFilter, hasFeedbackFilter, notHandledFilter}

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
    f = _.extend {}, filter, {rating: {$gt: 0}, createdAt: {$lt: today, $gte: weekAgo}}
    Thumb.count(f).exec (err, count) ->
      return next(err) if err
      defCountPosWeek.resolve(count)

    defCountNegWeek = Q.defer()
    f = _.extend {}, filter, {rating: {$lt: 0}, createdAt: {$lt: today, $gte: weekAgo}}
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
        subjectFilter
        agentFilter
        dateFromFilter
        dateToFilter
        hasFeedbackFilter
        notHandledFilter
        page: page
        totalPages: pages
        perPage: PER_PAGE
        getSubjectId: hooks.displaySubjectId or (thumb) -> thumb.subjectId
        getSubjectLink: hooks.displaySubjectLink or (thumb) -> 'javascript:void(0)'
        formatDate: (date) ->
          moment(date).utc().format("DD/MM/YYYY HH:mm:ss")
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

    sendResponse = ->
      switch accepts(req).type(['json', 'html'])
        when 'html'
          res.render('thankyou')
        when 'json'
          res.send({id: req.body.id})
        else
          res.status(200).end()

    sendResponse() if not feedback

    Q Thumb.update({_id: req.body.id}, {feedback}).exec()
    .then sendResponse
    .catch next

    if hooks.feedbackSaved
      Q Thumb.findOne({_id: req.body.id}).exec()
      .then hooks.feedbackSaved

  router.post '/handle', (req, res, next) ->
    handled = req.body.handled is '1'

    sendResponse = ->
      res.status(200).end()

    Q Thumb.update({_id: req.body.id}, {handled}).exec()
    .then sendResponse
    .catch next
