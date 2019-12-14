'use strict'

const fs = require('fs')
const crypto = require('crypto')

function readAsync (path, encoding) {
    return new Promise((resolve, reject) => {
        fs.readFile(path, encoding, (err, data) => {
            if (err) {
                return reject(err)
            }
            return resolve(data)
        })
    })
}

exports.encrypt = async (ctx, next) => {
    try {
        const key = await readAsync('./.pem/user.pem', 'utf8')
        const data = Buffer.from(JSON.stringify(ctx.body))
        const encrypted = crypto.publicEncrypt({
            key: key,
            padding: crypto.constants.RSA_PKCS1_PADDING
        }, data)
        ctx.body = encrypted.toString('base64')
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}

exports.decrypt = async (ctx, next) => {
    try {
        let key = await readAsync('./.pem/private.pem', 'utf8')
        const encrypted = Buffer.from(ctx.request.rawBody, 'base64')
        const decrypted = crypto.privateDecrypt({
            key: key,
            padding: crypto.constants.RSA_PKCS1_PADDING
        }, encrypted)
        ctx.request.body = JSON.parse(decrypted.toString('utf8'))
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}
