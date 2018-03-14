const chai = require('chai')
const { expect } = chai
chai.should()
const request = require('supertest')

describe('Thumbs', () => {
  it('should create a new thumb', done =>
    request(app)
      .post('/thumbs')
      .send({
        rating: 1,
        serviceId: 'test',
        subjectId: 'test_001'
      })
      .expect(200)
      .end(done))

  it('should honour uniqueId', done => {
    const uniqueId = `test_${Math.floor(Math.random() * 99999999)}`

    return request(app)
      .post('/thumbs')
      .send({
        rating: -1,
        serviceId: 'test',
        subjectId: 'test_001',
        uniqueId
      })
      .expect(200)
      .end((err, res) => {
        if (err) {
          done(err, res)
        }
        return request(app)
          .post('/thumbs')
          .send({
            rating: -1,
            serviceId: 'test',
            subjectId: 'test_001',
            uniqueId
          })
          .expect(400, 'Duplicate thumb')
          .end(done)
      })
  })
})
