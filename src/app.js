'use strict'

if (!process.env.NODE_ENV || process.env.NODE_ENV === 'development') {
    require('dotenv').config()
}

const Koa = require('koa')
const bodyParser = require('koa-bodyparser')
const router = require('./controllers/index')
const { logger } = require('./middleware/logger')

const port = 3000

const app = new Koa()

app
.use(logger)
.use(bodyParser())
.use(router.routes())
// .use(router.allowedMethods())

app.listen(port, () => {
    console.log(`Api listening on port ${port}`)
})
