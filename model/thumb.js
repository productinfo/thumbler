mongoose = require('mongoose')
paginate = require('mongoose-paginate')

ThumbSchema = new mongoose.Schema {
  rating:    {type: Number, required: true}
  serviceId: {type: String, required: true}
  subjectId: {type: String, required: true}
  uniqueId:  {type: String, unique: true, sparse: true}
  feedback:  {type: String}
  handled:   {type: Boolean, required: false}
  user: {
    name: String
    email: String
    company: String
    ip: {type: String}
  }
  agent: {
    name: String
  }
  createdAt: {type: Date, default: Date.now}
}

ThumbSchema.plugin paginate

###
Returns summary of positive/negative thumbs for a particular service, grouped by agent.
@param {string} serviceId Service ID to match
@param  {Date} from Datetime from
@param  {Date} to   Datetime to (exclusive)
@return {mongoose.Aggregate} Aggregate object you can call exec() on
###
ThumbSchema.statics.getServiceSummary = (serviceId, from, to) ->
  # If you want to put this into CLI, see QUERIES.md for copy-paste
  return this.aggregate({
    $match: {
      createdAt: { $gte : from, $lt: to},
      serviceId: serviceId,
      uniqueId: { $regex: /^[^_]+$/ }
    }
  },
  {
    $project: {
      'agent.name': 1,
      positive: { $cond: [{$gte: [ '$rating', 0]}, 1, 0]},
      negative: { $cond: [{$lt: [ '$rating', 0]}, 1, 0]}
    }
  },
  {
    $group: {
      _id: '$agent.name',
      positive: {$sum: '$positive'},
      negative: {$sum: '$negative'}
    }
  })

module.exports = Thumb = mongoose.model('Thumb', ThumbSchema)
