'use strict'

const { db } = require('./../utils/client')

const key = process.env.DB_KEY

exports.findAll = () => db.query(`SELECT name FROM accounts ORDER BY name`)

exports.findOne = name => db.query(`SELECT name, email, username, ` +
    `CAST(AES_DECRYPT(password, :key) AS CHAR(64)) decrypted_password ` +
    `FROM accounts WHERE name=:name`, {
    name: name,
    key: key
})

exports.insert = (name, email, username, password) => db.query(`INSERT INTO accounts` +
    `(name, email, username, password) VALUES (:name, :email, :username, AES_ENCRYPT(:password, :key))`, {
        name: name,
        email: email,
        username: username,
        password: password,
        key: key
    })