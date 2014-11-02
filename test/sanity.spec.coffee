chai = require('chai')
expect = chai.expect
chai.should()
request = require('supertest')

describe "Sanity", ->
  it "should be sane", (done) ->

    expect(1).to.equal(1)
    1.should.equal(1)

    request(app)
      .get('/sanity')
      .expect(404, "Sanity not found")
      .end(done)
