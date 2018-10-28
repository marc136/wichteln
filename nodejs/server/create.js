/**
 * Contains code for POST to /create
 */

const { print, randomString } = require('./common')
const db = require('./db')
const schema = require('./schema')

async function createEvent (ctx, next) {
  // print(ctx.request.body)
  const data = ctx.request.body
  const badRequest = sendError(ctx, 400)

  const error = schema.validate('create', data)
  if (error) {
    console.error('invalid schema', error)
    // return ctx.throw(400, 'InvalidSchema') // returns only string body
    return badRequest('InvalidSchema')
  }

  if (!data.mayStoreEmails) return badRequest('MayStoreEmailFalse')

  const participants = data.participants
    .map(participant => {
      // drop other fields
      return {
        name: participant.name.trim(),
        email: participant.email.trim(),
        id: randomString(10)
      }
    })
    .filter(participant => {
      return participant.name !== '' || participant.email !== ''
    })

  // Return error on duplicate names
  // Allow duplicate email addresses

  if (participants.length < 4) return badRequest('TooFewParticipants')

  const id = db.generateId()
  shuffleArrayInPlace(participants)
  const result = { id, ...data, id, participants }
  db.set(id, result)

  print(db)

  // hide the sorting because it equals the chain of gifts
  sortParticipantsInPlace(result.participants)
  ctx.body = result
}

function shuffleArrayInPlace (array) {
  // Durstenfeld shuffle
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    const temp = array[i]
    array[i] = array[j]
    array[j] = temp
  }
}

function sortParticipantsInPlace(array) {
  array.sort(compareParticipants)
}

function compareParticipants(a, b) {
  a = (a.name || a.email).toLowerCase()
  b = (b.name || b.email).toLowerCase()
  
  if (a < b) return -1
  else if (a > b) return 1
  else return 0
}

function sendError (ctx, code) {
  return error => {
    ctx.status = code
    ctx.body = { error }
  }
}

module.exports = createEvent
