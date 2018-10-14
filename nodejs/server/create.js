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

  const participants = data.participants.filter(participant => {
    return participant.name.trim() !== '' || participant.email.trim() !== ''
  })

  if (participants.length < 4) return badRequest('TooFewParticipants')

  print({ participants })
  // if (data.participants)

  ctx.body = ctx.request.body
}

function sendError (ctx, code) {
  return error => {
    ctx.status = code
    ctx.body = { error }
  }
}

module.exports = createEvent
