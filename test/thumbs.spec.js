// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const chai = require('chai');
const { expect } = chai;
chai.should();
const request = require('supertest');

describe("Thumbs", function() {
  it("should create a new thumb", done =>

    request(app)
      .post('/thumbs')
      .send({
        rating: 1,
        serviceId: "test",
        subjectId: "test_001"
      })
      .expect(200)
      .end(done)
  );

  return it("should honour uniqueId", function(done) {

    const uniqueId = `test_${Math.floor(Math.random()*99999999)}`;

    return request(app)
      .post('/thumbs')
      .send({
        rating: -1,
        serviceId: "test",
        subjectId: "test_001",
        uniqueId
      })
      .expect(200)
      .end(function(err, res) {
        if (err) { done(err, res); }
        return request(app)
          .post('/thumbs')
          .send({
            rating: -1,
            serviceId: "test",
            subjectId: "test_001",
            uniqueId
          })
          .expect(400, "Duplicate thumb")
          .end(done);
    });
  });
});
