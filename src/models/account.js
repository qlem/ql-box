'use strict'

const { pool } = require('./../utils/client')

const key = process.env.DB_KEY

exports.findAll = () => pool.query('SELECT name FROM accounts ORDER BY name')

exports.findOne = name => pool.query('SELECT name, email, username, ' +
    'CAST(AES_DECRYPT(password, :key) AS CHAR(64)) decrypted_password ' +
    'FROM accounts WHERE name=:name', {
        name: name,
        key: key
    })

exports.insert = (name, email, username, password) => pool.query('INSERT INTO accounts' +
    '(name, email, username, password) ' + 
    'VALUES (:name, :email, :username, AES_ENCRYPT(:password, :key))', {
        name: name,
        email: email,
        username: username,
        password: password,
        key: key
    })
