mongoose = require('mongoose')

ThumbSchema = new mongoose.Schema {
  rating:    {type: Number, required: true}
  serviceId: {type: String, required: true}
  subjectId: {type: String, required: true}
  uniqueId:  {type: String, unique: true, sparse: true}
  createdAt: {type: Date, default: Date.now}
  ip: {type: String}
}

module.exports = Thumb = mongoose.model('Thumb', ThumbSchema)