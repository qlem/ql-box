const Router = require('koa-router')
const account = require('./account')

const router = new Router()

router.use('/account', account.routes(), account.allowedMethods())

module.exports = router