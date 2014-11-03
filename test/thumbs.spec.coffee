chai = require('chai')
expect = chai.expect
chai.should()
request = require('supertest')

describe "Thumbs", ->
  it "should create a new thumb", (done) ->

    request(app)
      .post('/thumbs')
      .send {
        rating: 1
        serviceId: "test"
        subjectId: "test_001"
      }
      .expect(200)
      .end(done)

  it "should honour the uniqueId", (done) ->

    uniqueId = "test_#{Math.floor(Math.random()*99999999)}"

    request(app)
      .post('/thumbs')
      .send {
        rating: -1
        serviceId: "test"
        subjectId: "test_001"
        uniqueId: uniqueId
      }
      .expect(200)
      .end (err, res) ->
        done(err, res) if err
        request(app)
          .post('/thumbs')
          .send {
            rating: -1
            serviceId: "test"
            subjectId: "test_001"
            uniqueId: uniqueId
          }
          .expect(400, "Duplicate thumb")
          .end(done)
