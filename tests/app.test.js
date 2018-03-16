const process = require('process')
const request = require('supertest')

beforeAll(() => {
  process.env.DEBUG = 'thumbler:*'
  const thumbler = require('../app')
  global.app = thumbler.app
  return thumbler.run()
})

describe('Sanity', () => {
  test('should be sane', async (done) => {
    const response = await request(global.app).get('/sanity')
    expect(response.status).toBe(404)
    expect(response.text).toBe('Sanity not found')
    done()
  })
})

describe('Thumbs', () => {
  test('should create a new thumb', done =>
    request(global.app)
      .post('/thumbs')
      .send({
        rating: 1,
        serviceId: 'test',
        subjectId: 'test_001'
      })
      .expect(200)
      .end(done))

  test('should honour uniqueId', done => {
    const uniqueId = `test_${Math.floor(Math.random() * 99999999)}`

    return request(global.app)
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
        return request(global.app)
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
