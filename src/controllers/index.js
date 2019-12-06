const Router = require('koa-router')
const login = require('./login')

const router = new Router()

router.use('/login', login.routes(), login.allowedMethods())

module.exports = router