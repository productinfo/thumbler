/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const chai = require('chai');
const { expect } = chai;
chai.should();
const request = require('supertest');

describe("Sanity", () =>
  it("should be sane", function(done) {

    expect(1).to.equal(1);
    (1).should.equal(1);

    return request(app)
      .get('/sanity')
      .expect(404, "Sanity not found")
      .end(done);
  })
);
