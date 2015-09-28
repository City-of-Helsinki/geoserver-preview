express = require 'express'
routes = require './routes'
path = require 'path'
config = require 'config'

STATIC_URL = (config.get 'base_url') + config.get 'static_prefix'
GEOSERVER_URL = config.get 'geoserver_baseurl'
TILESERVER_URL = config.get 'tileserver_url'

startServer = ->
    app = express()
    app.set 'views', (path.join __dirname, './templates')
    app.set 'view engine', 'jade'
    app.use STATIC_URL, express.static './dist'

    routes.attachHandlers(app)

    # for prepending static file links in the templates
    app.locals['staticPrefix'] = (fpath) ->
        return STATIC_URL + fpath
    # pass also the data server addresses immediately for all views to use
    app.locals['tileserverUrl'] = TILESERVER_URL
    app.locals['geoserverUrl'] = GEOSERVER_URL

    server = app.listen (config.get 'express_port')

exports.createServer = startServer

startServer()
