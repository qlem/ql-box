'use strict'

const { db } = require('./../utils/client')

exports.findOne = username => db.query(`SELECT * FROM users WHERE (username=:username)`, {
    username: username
})