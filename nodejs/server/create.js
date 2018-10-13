/**
 * Contains code for POST to /create
 */

const { print, randomString } = require('./common')
const djv = require('djv')
const env = djv({
  version: 'draft-06'
})

const string = { type: 'string' }
const date = { ...string, pattern: '^\\d{4}-\\d{2}-\\d{2}$' }

// see http://json-schema.org/latest/json-schema-validation.html#rfc.toc
const createSchema = {
  type: 'object',
  required: [
    'kind',
    'mayStoreEmails',
    'participants',
    'deleteAfter',
    'deleteAfter',
    'startOn'
  ],
  properties: {
    kind: { enum: ['fixedList', 'inviteParticipants'] },
    mayStoreEmails: { type: 'boolean' },
    participants: {
      type: 'array',
      items: {
        type: 'object',
        required: ['name', 'email'],
        properties: {
          name: string,
          email: {
            oneOf: [{ const: '' }, { type: 'string', format: 'email' }]
          }
        }
      },
      uniqueItems: true
      // minItems: 4 // this is checked again after removing empty participants
    },
    deleteAfter: date,
    startOn: date
  }
}
env.addSchema('create', createSchema)

async function createEvent (ctx, next) {
  // print(ctx.request.body)
  const data = ctx.request.body
  const badRequest = sendError(ctx, 400)

  const error = env.validate('create', data)
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
