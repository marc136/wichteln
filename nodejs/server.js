// general imports
const fs = require('fs')
// const fetch = require('node-fetch')

// koa-specific imports
const Koa = require('koa')
const route = require('koa-route')
const bodyParser = require('koa-bodyparser')
const logger = require('koa-logger')
const serve = require('koa-static')
const rewrite = require('koa-rewrite')

// local imports
const createEvent = require('./server/create')
const db = require('./server/db')

/* istanbul ignore next */
const port = process.env.PORT || 8000

console.log('Starting server')

const app = new Koa()
app.use(logger())
/* istanbul ignore next */
app.use(
  bodyParser({
    onerror: function _bodyParserOnError (err, ctx) {
      console.error('err', err)
      ctx.throw(422, 'body parse error')
    }
  })
)

app.use(rewrite('/neu', '/'))
app.use(serve('../elm/build'), { defer: true })
app.use(route.post('/create', createEvent))

/* istanbul ignore next */
const server = app.listen(port).on('error', err => {
  console.error('ERROR: Will close program')
  console.error(err)
  process.exit(1)
})
console.log(`Listening on port ${port}`)

module.exports = server
