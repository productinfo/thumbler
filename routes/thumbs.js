const _ = require('lodash')
const express = require('express')
const paginate = require('express-paginate')
const accepts = require('accepts')
const router = express.Router()
const Thumb = require('../model/thumb')
const moment = require('moment')

// from moment docs:
// dow == 1 and doy == 4 means week starts Monday and first week that has Thursday is the
// first week of the year (but doy is NOT simply Thursday).
moment.updateLocale('en', {
  week: {
    dow: 1,
    doy: 4
  }
})

let hooks
try {
  /* eslint-disable node/no-missing-require, node/no-unpublished-require */
  hooks = require('../local_config/hooks')
} catch (e) {
  hooks = {}
}

const editableFields = [
  'rating',
  'serviceId',
  'uniqueId',
  'subjectId',
  'user.name',
  'user.email',
  'user.company',
  'user.ip',
  'agent.name',
  'type'
]

const filterFields = function (data, fields) {
  const out = {}
  for (let k of fields) {
    if (!data[k]) {
      continue
    }
    const parts = k.split('.')
    const lastPart = parts.pop()
    let o = out
    for (let part of parts) {
      o[part] = o[part] ? o[part] : {}
      o = o[part]
    }
    o[lastPart] = data[k]
  }
  return out
}

const getThumb = function (data) {
  const where = {}
  if (data.uniqueId) {
    where.uniqueId = data.uniqueId
  } else {
    where.serviceId = data.serviceId
    where.subjectId = data.subjectId
    where.rating = +data.rating
  }
  return Thumb.findOne(where).exec()
}

const getOrCreateThumb = function (data) {
  let thumbData = null
  return new Promise((resolve, reject) => {
    thumbData = filterFields(data, editableFields)
    if (typeof hooks.validateThumb === 'function') {
      hooks.validateThumb(thumbData)
    }
    thumbData =
      (typeof hooks.preprocessThumb === 'function'
        ? hooks.preprocessThumb(thumbData, data)
        : undefined) || thumbData
    return resolve(Thumb.create(thumbData))
  }).catch(err => {
    if ([11000, 11001].includes(err.code)) {
      // Duplicate thumb
      return getThumb(thumbData)
    } else {
      throw err
    }
  })
}

const createFilter = function ({
  subjectFilter,
  agentFilter,
  dateFromFilter,
  dateToFilter,
  hasFeedbackFilter,
  notHandledFilter,
  typeFilter
}) {
  const filter = {}

  if (agentFilter) {
    // Enable comma-separated values + whitepsace ignoring
    agentFilter = agentFilter
      .split(',')
      .map(i => _.trim(i))
      .join('|')
    filter['agent.name'] = new RegExp(agentFilter, 'i')
  }

  if (subjectFilter) {
    let matchAnywhere = false
    if (subjectFilter[0] === '*') {
      subjectFilter = subjectFilter.substr(1)
      matchAnywhere = true
    }
    const re = new RegExp(subjectFilter, 'i')
    const reBeginning = new RegExp(`^${subjectFilter}`, 'i')
    filter['$or'] = [
      { subjectId: matchAnywhere ? re : reBeginning },
      { 'user.name': re },
      { 'user.email': re },
      { 'user.company': re },
      { 'user.ip': re },
      { feedback: re }
    ]
  }

  if (dateFromFilter || dateToFilter) {
    let dateFrom, dateTo
    let d = dateFromFilter.split('/')
    if (d.length === 3) {
      dateFrom = `${d[2]}-${_.padStart(d[1], 2, '0')}-${d[0]}T00:00:00Z`
    }

    d = dateToFilter.split('/')
    if (d.length === 3) {
      dateTo = `${d[2]}-${_.padStart(d[1], 2, '0')}-${d[0]}T23:59:59Z`
    }

    if (dateFrom || dateTo) {
      filter['createdAt'] = {}
      if (dateFrom) {
        filter['createdAt']['$gte'] = new Date(dateFrom)
      }
      if (dateTo) {
        filter['createdAt']['$lte'] = new Date(dateTo)
      }
    }
  }

  if (hasFeedbackFilter) {
    filter['feedback'] = {
      $exists: true,
      $ne: ''
    }
  }

  if (notHandledFilter) {
    filter['handled'] = {
      $in: [false, null]
    }
  }

  if (typeFilter) {
    filter['type'] =
      typeFilter !== 'default' ? typeFilter : { $in: [null, 'default'] }
  }

  return filter
}

const PER_PAGE = 100

module.exports = function (debug = false) {
  router.use('/list', paginate.middleware(PER_PAGE, PER_PAGE))

  router.get('/summary', (req, res, next) => {
    const today = moment()
      .utc()
      .startOf('day')
      .toDate()
    const yesterday = moment()
      .utc()
      .subtract(1, 'day')
      .startOf('day')
      .toDate()
    const { serviceId } = req.query
    return Thumb.getServiceSummary(serviceId, yesterday, today).exec(
      (err, result) => res.json(err || result)
    )
  })

  router.get('/list', (req, res, next) => {
    const page = Math.max(1, req.query.page || 1)
    const typeFilter = req.query.type || 'default'
    const subjectFilter = req.query.subject || ''
    const agentFilter = req.query.agent || ''
    const dateFromFilter = req.query.date_from || ''
    const dateToFilter = req.query.date_to || ''
    const hasFeedbackFilter = !!req.query.has_feedback || false
    const notHandledFilter = !!req.query.not_handled || false
    const filter = createFilter({
      typeFilter,
      subjectFilter,
      agentFilter,
      dateFromFilter,
      dateToFilter,
      hasFeedbackFilter,
      notHandledFilter
    })

    const defList = new Promise(resolve => {
      Thumb.paginate(
        filter,
        { page, limit: PER_PAGE, sort: { createdAt: 'desc' } },
        function (err, result) {
          if (err) {
            return next(err)
          }
          return resolve({
            pages: result.pages,
            thumbs: result.docs,
            count: result.total
          })
        }
      )
    })

    const defCountPos = new Promise(resolve => {
      let f = _.extend({ rating: { $gt: 0 } }, filter)
      Thumb.count(f).exec(function (err, count) {
        if (err) {
          return next(err)
        }
        return resolve(count)
      })
    })

    const defCountNeg = new Promise(resolve => {
      let f = _.extend({ rating: { $lt: 0 } }, filter)
      Thumb.count(f).exec(function (err, count) {
        if (err) {
          return next(err)
        }
        return resolve(count)
      })
    })

    const lastWeekStart = moment()
      .utc()
      .subtract(1, 'week')
      .startOf('week')
      .toDate()
    const lastWeekEnd = moment()
      .utc()
      .subtract(1, 'week')
      .endOf('week')
      .toDate()

    const defCountPosWeek = new Promise(resolve => {
      let f = _.extend({}, filter, {
        rating: { $gt: 0 },
        createdAt: { $lte: lastWeekEnd, $gte: lastWeekStart }
      })
      Thumb.count(f).exec(function (err, count) {
        if (err) {
          return next(err)
        }
        return resolve(count)
      })
    })

    const defCountNegWeek = new Promise(resolve => {
      let f = _.extend({}, filter, {
        rating: { $lt: 0 },
        createdAt: { $lte: lastWeekEnd, $gte: lastWeekStart }
      })
      Thumb.count(f).exec(function (err, count) {
        if (err) {
          return next(err)
        }
        return resolve(count)
      })
    })

    const promises = [
      defList,
      defCountPos,
      defCountNeg,
      defCountPosWeek,
      defCountNegWeek
    ]

    return Promise.all(promises).then(
      ([
        { pages, thumbs, countAll },
        countPos,
        countNeg,
        countPosWeek,
        countNegWeek
      ]) =>
        res.render('index', {
          thumbs,
          countAll,
          countPos,
          countNeg,
          countPosWeek,
          countNegWeek,
          subjectFilter,
          agentFilter,
          dateFromFilter,
          dateToFilter,
          hasFeedbackFilter,
          notHandledFilter,
          typeFilter,
          page,
          totalPages: pages,
          perPage: PER_PAGE,
          getSubjectId: hooks.displaySubjectId || (thumb => thumb.subjectId),
          getSubjectLink:
            hooks.displaySubjectLink || (thumb => 'javascript:void(0)'),
          formatDate (date) {
            return moment(date)
              .utc()
              .format('DD/MM/YYYY HH:mm:ss')
          },
          truncateFeedback (feedback) {
            if (feedback && feedback.length > 80) {
              const words = feedback.replace(/\s+/g, ' ').split(' ')
              let truncated = ''
              for (let w of words) {
                if (truncated.length < 70) {
                  truncated += ` ${w}`
                }
              }
              feedback = truncated.substr(0, 80) + '...'
            }
            return feedback
          }
        })
    )
  })

  router.post('/', (req, res, next) => {
    const data = _.extend({}, req.body, { 'user.ip': req.ip })
    return getOrCreateThumb(data)
      .then(function (thumb) {
        switch (accepts(req).type(['json', 'html'])) {
          case 'html':
            const view = res.locals.isMaster ? 'vote-master' : 'vote'
            return res.render(view, { thumb })
          case 'json':
            return res.send({ id: thumb.id })
          default:
            return res.status(200).end()
        }
      })
      .catch(function (err) {
        if ([11000, 11001].includes(err.code)) {
          return res.status(400).render('error', {
            error: _.assign(new Error(), {
              title: 'Duplicate thumb',
              message:
                'This thumb has already been created. Nothing to see here.'
            })
          })
        } else if (err.name === 'ValidationError') {
          return res.status(400).render('error', { error: err })
        } else {
          return next(err)
        }
      })
  })

  router.get('/vote', (req, res, next) => {
    const data = _.extend({}, req.query, { 'user.ip': req.ip })
    return getOrCreateThumb(data)
      .then(function (thumb) {
        switch (accepts(req).type(['json', 'html'])) {
          case 'html':
            const view = res.locals.isMaster ? 'vote-master' : 'vote'
            return res.render(view, { thumb })
          case 'json':
            return res.send({ id: thumb.id })
          default:
            return res.status(200).end()
        }
      })
      .catch(function (err) {
        if (err.name === 'ValidationError') {
          return res.status(400).render('error', { error: err })
        } else {
          return next(err)
        }
      })
  })

  router.post('/feedback', (req, res, next) => {
    const isMaster = req.body.type === 'toggl-master' || res.locals.isMaster
    const feedback = (req.body.feedback || '').trim()

    const sendResponse = () => {
      switch (accepts(req).type(['json', 'html'])) {
        case 'html':
          const view = isMaster ? 'thankyou-master' : 'thankyou'
          return res.render(view)
        case 'json':
          return res.send({ id: req.body.id })
        default:
          return res.status(200).end()
      }
    }

    if (!feedback) {
      sendResponse()
    }

    Thumb.update({ _id: req.body.id }, { feedback })
      .exec()
      .then(sendResponse)
      .catch(next)

    if (hooks.feedbackSaved) {
      return Thumb.findOne({ _id: req.body.id })
        .exec()
        .then(hooks.feedbackSaved)
    }
  })

  return router.post('/handle', (req, res, next) => {
    const handled = req.body.handled === '1'

    const sendResponse = () => res.status(200).end()

    return Thumb.update({ _id: req.body.id }, { handled })
      .exec()
      .then(sendResponse)
      .catch(next)
  })
}
