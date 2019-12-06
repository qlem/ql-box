'use strict'

const { db } = require('./../utils/client')

const key = process.env.DB_KEY

exports.findAll = () => db.query(`SELECT title FROM logins_passwords ORDER BY title`)

exports.findOne = title => db.query(`SELECT title, email, username, ` +
	`CAST(AES_DECRYPT(password, :key) AS CHAR(64)) decrypted_password ` +
	`FROM logins_passwords WHERE title=:title`, {
	title: title,
	key: key
})

exports.insert = (title, email, username, password) => db.query(`INSERT INTO logins_passwords` +
	`(title, email, username, password) VALUES (:title, :email, :username, AES_ENCRYPT(:password, :key))`, {
		title: title,
		email: email,
		username: username,
		password: password,
		key: key
	})