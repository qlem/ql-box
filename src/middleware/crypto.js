'use strict'

const fs = require('fs')
const crypto = require('crypto')

const algorithm = 'aes-128-cbc'

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

function randomBytesAsync (size) {
    return new Promise((resolve, reject) => {
        crypto.randomBytes(size, (err, buf) => {
            if (err) {
                return reject(err)
            }
            return resolve(buf)
        })
    })
}

exports.encrypt = async (ctx, next) => {
    try {
        const publicKey = await readAsync('./.pem/user.pem', 'utf8')
        const key = await randomBytesAsync(16)
        let iv = await randomBytesAsync(16)
        
        const cipher = crypto.createCipheriv(algorithm, key, iv)
        let encrypted = cipher.update(JSON.stringify(ctx.body), 'utf8', 'base64')
        encrypted += cipher.final('base64')
        encrypted = encrypted.toString('base64')
      
        let encryptedKey = crypto.publicEncrypt({
            key: publicKey,
            padding: crypto.constants.RSA_PKCS1_OAEP_PADDING
        }, key)
        encryptedKey = encryptedKey.toString('base64')
        iv = iv.toString('base64')

        ctx.body = `${iv}:${encryptedKey}:${encrypted}`
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}

exports.decrypt = async (ctx, next) => {
    try {
        const array = ctx.request.rawBody.split(':')
        if (array.length != 3) {
            ctx.status = 400
            return
        }

        let iv = Buffer.from(array[0], 'base64')
        iv = Buffer.from(iv.toString(), 'hex')
        
        const privateKey = await readAsync('./.pem/private.pem', 'utf8')
        let key = crypto.privateDecrypt({
            key: privateKey,
            padding: crypto.constants.RSA_PKCS1_OAEP_PADDING
        }, Buffer.from(array[1], 'base64'))
        key = Buffer.from(key.toString(), 'hex')
        
        const encrypted = Buffer.from(array[2], 'base64')
        const decipher = crypto.createDecipheriv(algorithm, key, iv)
        let decrypted = decipher.update(encrypted, 'base64', 'utf8')
        decrypted += decipher.final('utf8')
        
        ctx.request.body = JSON.parse(decrypted)
        return next()
    } catch (err) {
        console.error(err)
        ctx.status = 500
    }
}
