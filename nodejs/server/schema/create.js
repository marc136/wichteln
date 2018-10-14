const { string, date } = require('./shared')

// see http://json-schema.org/latest/json-schema-validation.html#rfc.toc
const schema = {
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

module.exports = function add (env) {
  env.addSchema('create', schema)
  return env
}
