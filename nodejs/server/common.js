const crypto = require('crypto')
const util = require('util')
const clone = require('deep-copy')

function print (obj) {
  return console.log(util.inspect(obj, false, null, false))
}

function randomString (len) {
  if (!Number.isInteger(len)) len = 8

  return crypto.randomBytes(Math.ceil(len / 2)).toString('hex').slice(0, len)
}

function copies (obj, count) {
  const result = new Array(count)

  for (let i = count - 1; i >= 0; i--) {
    result[i] = clone(obj)
  }
  return result
}

module.exports = { print, randomString, copies }
