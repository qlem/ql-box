'use strict'

const Router = require('koa-router')
const Auth = require('./../middleware/auth')
const Account = require('./../models/account')

const router = new Router()

router.use(Auth.auth)

function checkFields (data) {
    if (data.name == null || data.password == null || data.email == null && data.username == null || 
        data.name == '' || data.password == '' || data.email == '' && data.username == '') {
        return false
    }
    Object.keys(data).forEach(key => {
        if (data[key] == '') {
            data[key] = null
        }
    })
    return true
}

function checkBody (ctx, next) {
    try {
        const body = ctx.request.body
        if (body == {} || body.data == null) {
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
        if (ctx.query == {} || ctx.query.name == null) {
            ctx.status = 400
            return
        }
        const res = await Account.findOne(ctx.query.name)
        if (res.length < 1) {
            ctx.body = {}
        } else {
            ctx.body = res[0]
        }
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
})

router.get('/all', async (ctx, next) => {
    try {
        const res = await Account.findAll()
        const array = []
        res.forEach(item => {
            array.push(item.name)
        })
        ctx.body = array
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
})

router.post('/', checkBody, async (ctx, next) => {
    try {
        const data = ctx.request.body.data
        if (!checkFields(data)) {
            ctx.status = 400
            return
        }
        const res = await Account.insert(data.name, data.email, data.username, data.password)
        ctx.body = res
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
})

router.post('/bulk', checkBody, async (ctx, next) => {
    try {
        const data = ctx.request.body.data
        if (!Array.isArray(data)) {
            ctx.status = 400
            return
        }
        const result = {
            inserted: 0,
            failed: 0
        }
        for (let i = 0; i < data.length; i++) {
            if (!checkFields(data[i])) {
                result.failed++
            } else {
                try {
                    const res = await Account.insert(data[i].name, data[i].email, data[i].username, data[i].password)
                    result.inserted++
                } catch (err) {
                    result.failed++
                }
            }
        }
        ctx.body = result
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
})

module.exports = router