const tap = require('tap')

const { randomString } = require('../server/common')

tap.test('randomString NaN fallback', t => {
  hasLength(randomString(), 8)
  hasLength(randomString(undefined), 8)
  hasLength(randomString('a'), 8)
  hasLength(randomString(12.3), 8)
  hasLength(randomString(-3), 8)
  hasLength(randomString(0), 8)

  t.end()
})

tap.test('randomString length', t => {
  const tests = [1, 5, 8, 2839]

  tests.map(length => hasLength(randomString(length), length))
  t.end()
})

function hasLength (str, length) {
  return tap.ok(str.length === length, `"${str}".length != ${length}`)
}
