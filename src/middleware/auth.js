'use strict'

const compose = require('koa-compose')
const bcrypt = require('bcrypt')
const User = require('./../models/user')

function a (ctx, next) {
    const regex = /^Basic [A-Za-z0-9+/]+={0,2}$/
    const credentials = ctx.get('Authorization')
    if (!credentials || !regex.test(credentials)) {
        ctx.status = 401
        return
    }
    ctx.state.credentials = credentials
    return next()
}

function b (ctx, next) {
    const credentials = Buffer.from(ctx.state.credentials.substring(6), 'base64')
        .toString().split(':')
    if (credentials.length != 2) {
        ctx.status = 401
        return
    }
    ctx.state.credentials = credentials
    return next()
}

async function c (ctx, next) {
    try {
        const username = ctx.state.credentials[0]
        const res = await User.findOne(username)
        if (res.lenth < 1) {
            ctx.status = 401
            return
        }
        ctx.state.user = res[0]
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}

async function d (ctx, next) {
    try {
        const password = ctx.state.credentials[1]
        const hash = ctx.state.user.password
        const valid = await bcrypt.compare(password, hash)
        if (!valid) {
            ctx.status = 401
            return
        }
        delete ctx.state.credentials
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}

exports.auth = compose([a, b, c, d])
