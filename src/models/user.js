'use strict'

const { pool } = require('./../utils/client')

exports.findOne = username => {
    const sql = 'SELECT * FROM users WHERE (username=:username)'
    return pool.query(sql, {username: username})
}
