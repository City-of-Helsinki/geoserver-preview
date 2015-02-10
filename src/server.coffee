express = require 'express'
routes = require './routes'
path = require 'path'
config = require 'config'

exports.createServer = ->
    app = express()
    app.set 'views', (path.join __dirname, './templates')
    app.set 'view engine', 'jade'
    app.use (express.static './dist')

    routes.attachHandlers(app)

    server = app.listen (config.get 'express_port')