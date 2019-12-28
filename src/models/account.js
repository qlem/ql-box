'use strict'

const { pool } = require('./../utils/client')

const key = process.env.DB_KEY

exports.find = name => {
    const sql = 'SELECT name, username, email, CAST(AES_DECRYPT(password, :key) ' + 
        'AS CHAR(64)) password FROM accounts WHERE name=:name'
    return pool.query(sql, {name: name, key: key})
}

exports.insert = account => {
    account.key = key
    const sql = 'INSERT INTO accounts (name, username, email, password) ' + 
        'VALUES (:name, :username, :email, AES_ENCRYPT(:password, :key))'
    return pool.query(sql, account)
}

exports.update = account => {
    account.key = key
    const sql = 'UPDATE accounts SET name = :name, username = :username, ' +
        'email = :email, password = AES_ENCRYPT(:password, :key) WHERE name=:name'
    return pool.query(sql, account)
}

exports.delete = name => {
    const sql = 'DELETE FROM accounts WHERE name=:name'
    return pool.query(sql, {name: name})
}

exports.findAll = () => pool.query('SELECT name FROM accounts ORDER BY name')

exports.insertMany = data => {
    data.forEach(item => {
        item.key = key
    })
    const sql = 'INSERT INTO accounts (name, username, email, password) VALUES ' + 
        '(:name, :username, :email, AES_ENCRYPT(:password, :key))'
    return pool.batch(sql, data)
}
