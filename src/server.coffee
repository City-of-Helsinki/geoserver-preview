express = require 'express'
routes = require './routes'
path = require 'path'
config = require 'config'

STATIC_URL = (config.get 'base_url') + config.get 'static_prefix'

exports.createServer = ->
    app = express()
    app.set 'views', (path.join __dirname, './templates')
    app.set 'view engine', 'jade'
    app.use STATIC_URL, express.static './dist'

    routes.attachHandlers(app)

    server = app.listen (config.get 'express_port')
