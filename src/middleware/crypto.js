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
        
        const array = ctx.request.rawBody.split(':')
        console.log(array[1])
        if (array.length != 3) {
            ctx.status = 400
            return
        }

        const algorithm = 'aes-128-cbc'

        let iv = Buffer.from(array[0], 'base64')
        iv = Buffer.from(iv.toString(), 'hex')
        
        const key = await readAsync('./.pem/private.pem', 'utf8')
        let simKey = crypto.privateDecrypt({
            key: key,
            padding: crypto.constants.RSA_PKCS1_PADDING
        }, Buffer.from(array[1], 'base64'))
        simKey = Buffer.from(simKey.toString(), 'hex')
        
        const encrypted = Buffer.from(array[2], 'base64')
        const decipher = crypto.createDecipheriv(algorithm, simKey, iv)
        let decrypted = decipher.update(encrypted, 'base64', 'utf8')
        decrypted += decipher.final('utf8')
        console.log(decrypted)

        // ctx.request.body = JSON.parse(decrypted.toString('utf8'))
        // return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}
