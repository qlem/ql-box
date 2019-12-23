'use strict'

const { pool } = require('./../utils/client')

exports.findOne = username => pool.query('SELECT * FROM users WHERE (username=:username)', {username: username})
