const djv = require('djv')
const env = djv({
  version: 'draft-06'
})

require('./schema/create')(env)

module.exports = env
