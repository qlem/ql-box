'use strict'

exports.logger = async (ctx, next) => {
    const start = Date.now()
    const date = new Date(start)
    await next()
    const time = Date.now() - start
    const log = `${date.toISOString()} - ${ctx.ip} - ${ctx.method} ${ctx.url} - ` + 
        `${ctx.status} - ${time}ms`
    console.log(log)
}
