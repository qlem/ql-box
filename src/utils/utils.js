'use strict'

exports.timeout = ms => new Promise(resolve => {
    setTimeout(() => resolve(), ms)
})
