const chai = require('chai');
const { expect } = chai;
chai.should();
const request = require('supertest');

describe("Sanity", () =>
  it("should be sane", (done) => {

    expect(1).to.equal(1);
    (1).should.equal(1);

    return request(app)
      .get('/sanity')
      .expect(404, "Sanity not found")
      .end(done);
  })
);
