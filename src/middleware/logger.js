'use strict'

exports.logger = async (ctx, next) => {
    const start = Date.now()
    await next()
    const time = Date.now() - start
    const log = `${ctx.method} - ${ctx.ip} - ` + 
    `${ctx.querystring ? ctx.path + ' ' + ctx.querystring : ctx.path} - ` +
    `${ctx.status} - ${time}ms`
    console.log(log)
}