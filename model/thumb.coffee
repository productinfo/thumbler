mongoose = require('mongoose')

ThumbSchema = new mongoose.Schema {
  rating:    {type: Number, required: true}
  serviceId: {type: String, required: true}
  subjectId: {type: String, required: true}
  uniqueId:  {type: String, unique: true, sparse: true}
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

module.exports = Thumb = mongoose.model('Thumb', ThumbSchema)