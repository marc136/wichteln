const tap = require('tap')
const supertest = require('supertest')
const { copies, print } = require('../server/common')
const clone = require('deep-copy')

// start the server
process.env.PORT = 7832
const server = require('../server')
const request = supertest(server)

const successParticipants = [
  { name: 'wert', email: '' },
  { name: '', email: 'wx.yz@abc.de' },
  { name: '1', email: 'asdf@example.org' },
  { name: 'wret', email: '' }
]
const successBody = {
  kind: 'fixedList',
  participants: successParticipants,
  mayStoreEmails: true,
  deleteAfter: '2018-11-13',
  startOn: '2018-10-13'
}

async function tests (t) {
  await request
    .post('/create')
    .send(successBody)
    .set('Accept', 'application/json')
    .expect('Content-Type', /json/)
    .expect(200)
    .then(response => {
      // print(response.body)
      t.ok(response.body.id, 'Should contain an id')
      delete response.body.id

      // order of participants is not guaranteed
      response.body.participants.forEach(participant => {
        for (let other of successParticipants) {
          if (
            participant.name === other.name &&
            participant.email === other.email
          ) {
            return 'success'
          }
        }
        // matching participant was not found
        t.fail(`Could not find participant ${JSON.stringify(participant)}`)
      })

      // ensure other fields match
      delete response.body.participants
      const successCopy = clone(successBody)
      delete successCopy.participants
      t.deepEqual(response.body, successCopy)
      // t.end())
    })

  await wrongSchemata(t)
  await wrongParamValues(t)
}

async function wrongSchemata (t) {
  const label = index => `wrongSchema[${index}]`

  const wrongSchema = copies(successBody, 11)

  delete wrongSchema[0].kind
  wrongSchema[1].kind = 'unknown'
  wrongSchema[2].participants.push({ name: '' })
  wrongSchema[3].participants.push({ email: '' })
  wrongSchema[4].participants.push({ name: '', email: 'invalid' })
  wrongSchema[5].mayStoreEmails = 'true'
  delete wrongSchema[6].deleteAfter
  wrongSchema[7].deleteAfter = '2018-1-13'
  delete wrongSchema[8].startOn
  wrongSchema[9].startOn = '2018-11-1a'
  wrongSchema[10].startOn = '201-11-11'

  return Promise.all(
    wrongSchema.map((body, index) =>
      request
        .post('/create')
        .send(body)
        .expect('Content-Type', /json/)
        .expect(400)
        .catch(ex => {
          // add label to error message
          ex.message = `${label(index)} ${ex.message}`
          return Promise.reject(ex)
        })
        .then(r =>
          t.deepEqual(r.body, { error: 'InvalidSchema' }, label(index))
        )
    )
  )
}

async function wrongParamValues (t) {
  const label = index => `wrongValues[${index}]`

  const wrongValues = [
    {
      body: { ...clone(successBody), mayStoreEmails: false },
      error: 'MayStoreEmailFalse'
    },
    {
      body: {
        ...clone(successBody),
        participants: [
          ...successParticipants.splice(0, 1),
          { name: '', email: '' }
        ]
      },
      error: 'TooFewParticipants' // 4 participants, but one is empty
    }
  ]

  return Promise.all(
    wrongValues.map(({ body, error }, index) => {
      console.log(`wrongValues ${index}`)
      return request
        .post('/create')
        .send(body)
        .expect('Content-Type', /json/)
        .expect(400)
        .catch(ex => {
          // add label to error message
          ex.message = `${label(index)} ${ex.message}`
          return Promise.reject(ex)
        })
        .then(response => {
          t.deepEqual(response.body, { error }, label(index))
        })
    })
  )
}

tap.test(tests).catch(tap.threw).then(() => server.close())
