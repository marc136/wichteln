const { print, randomString } = require('./common')
const clone = require('deep-copy')

// "database"
function DB () {}
const db = new DB()

/**
 * generate a new unique id
 */
function generateId () {
  let id, tries = 0, max = 10 ** 6
  do {
    id = randomString(8)
    /* istanbul ignore if */
    if (++tries > max) throw new Error('Could not generate unique id')
  } while (db[id])
  return id
}
DB.prototype.generateId = generateId

// DB.prototype.append = function append (content) {
//   return this.set(generateId(), content)
// }

DB.prototype.set = function set (id, content) {
  db[id] = clone(content)
  return id
}

module.exports = db
