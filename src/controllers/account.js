'use strict'

const Router = require('koa-router')
const Auth = require('./../middleware/auth')
const Crypto = require('./../middleware/crypto')
const Account = require('./../models/account')

const router = new Router()

router.use(Auth.auth)

function checkBody (ctx, next) {
    try {
        const body = ctx.request.body
        if (Object.keys(body).length === 0 || !body.data) {
            ctx.status = 400
            return
        }
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}

router.get('/', async (ctx, next) => {
    try {
        if (!ctx.query.name) {
            ctx.status = 400
            return
        }
        const res = await Account.find(ctx.query.name)
        if (res.length === 0) {
            ctx.body = {}
        } else {
            ctx.body = res[0]
        }
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}, Crypto.encrypt)

router.get('/all', async (ctx, next) => {
    try {
        const res = await Account.findAll()
        const array = []
        res.forEach(item => {
            array.push(item.name)
        })
        ctx.body = array
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}, Crypto.encrypt)

router.post('/', Crypto.decrypt, checkBody, async (ctx, next) => {
    try {
        const data = ctx.request.body.data
        if (!data.name || !data.password || !data.email && !data.username) {
            ctx.status = 400
            return
        }
        const res = await Account.insert(data)
        ctx.body = {
            inserted: res.affectedRows
        }
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}, Crypto.encrypt)

router.post('/bulk', Crypto.decrypt, checkBody, async (ctx, next) => {
    try {
        const data = ctx.request.body.data
        if (!Array.isArray(data)) {
            ctx.status = 400
            return
        }
        const res = await Account.insertMany(data)
        ctx.body = {
            inserted: res.affectedRows
        }
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}, Crypto.encrypt)

router.post('/update', Crypto.decrypt, checkBody, async (ctx, next) => {
    try {
        const data = ctx.request.body.data
        if (!data.name || !data.password || !data.email && !data.username) {
            ctx.status = 400
            return
        }
        const res = await Account.update(data)
        ctx.body = {
            updated: res.affectedRows
        }
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}, Crypto.encrypt)

router.delete('/', async (ctx, next) => {
    try {
        if (!ctx.query.name) {
            ctx.status = 400
            return
        }
        const res = await Account.delete(ctx.query.name)
        ctx.body = {
            deleted: res.affectedRows
        }
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}, Crypto.encrypt)

module.exports = router
