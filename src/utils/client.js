'use strict'

const mariadb = require('mariadb')

const pool = mariadb.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PWD,
    database: process.env.DB_DATABASE,
    connectionLimit: 10,
    namedPlaceholders: true
})

exports.pool = pool
