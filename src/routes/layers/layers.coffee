config = require 'config'
request = require 'request'
async = require 'async'


WFS_DOWNLOAD_FORMATS = {'CSV':'CSV', 'GML2':'GML2', 'GML3.1':'text/xml; subtype=gml/3.1.1', 'GML3.2':'application/gml+xml; version=3.2', 'GeoJSON':'application/json', 'KML':'application/vnd.google-earth.kml+xml', 'ShapeFile':'SHAPE-ZIP'}
WMS_DOWNLOAD_FORMATS = {'AtomPub':'atom', 'GIF':'image/gif', 'GeoRSS':'application/rss+xml', 'GeoTIFF':'image/geotiff', 'GeoTIFF 8-bits':'image/geotiff8', 'JPEG':'image/jpeg', 'KML (Compressed)':'application/vnd.google-earth.kmz+xml', 'KML (Network link)': 'application/vnd.google-earth.kml+xml;mode=networklink', 'KML (Plain)':'application/vnd.google-earth.kml+xml', 'PDF':'application/pdf', 'PNG':'image/png', 'PNG 8-bit':'image/png;+mode=8bit', 'SVG':'image/svg', 'Tiff':'image/tiff', 'Tiff 8-bits':'image/tiff8', 'OpenLayers':'text/html;+subtype=openlayers'}

exports.attachHandlers = (app) ->
    #POST
    #nothing here, could be app.post '/layers'

    # GET
    # here we define the serial steps to take when this route is GETted
    app.get '/layers',
        parseQueryParams,
        getInitialAsyncMultipleFromGeoserver, #uses async.map
        getResourceDocumentAsyncMultipleFromGeoserver, #uses async.map
        (req, res) -> # at this point we've populated res.locals for the template to use
            res.render 'layerlist', {'wfs_formats':WFS_DOWNLOAD_FORMATS, 'wms_formats':WMS_DOWNLOAD_FORMATS}


parseQueryParams = (req, res, next) ->
    # TODO better error handling
    if not req.query.layers? or req.query.layers == ''
        res.locals.layerNames = []
        return next()

    layerNames = req.query.layers.split ','
    res.locals.layerNames = layerNames #save it into locals for the next function to use
    next()

getInitialAsyncMultipleFromGeoserver = (req, res, next) ->
    #we want to GET information from the geoserver separately for all layer names
    async.map res.locals.layerNames, restGetLayerFromGeoserver, (err, layerData) ->
        if err?
            return next err
        # layerData is now a list of all the layerData from the individual gets
        res.locals.layerData = layerData
        next()
 
restGetLayerFromGeoserver = (layerName, cb) ->
    name = layerName
    url = (config.get 'geoserver_baseurl') + "/rest/layers/#{name}"
    layerGetData = {}
    request
        'method': 'GET'
        'url': url,
        'json': true
        'auth':
            'user': config.get 'geoserver_user'
            'pass': config.get 'geoserver_pass'
            'sendImmediately': true # waiting for contest results in 404
        (err, resp, body) ->
            return cb err if err?
            #construct an object from the data we got back in the response
            layerGetData['name'] = name
            layerGetData['statusCode'] = resp.statusCode
            # console.log resp.layer
            #if there was a problem we'll still have saved the name, statuscode and status
            if resp.statusCode != 200
                layerGetData['status'] = 'KO'
                # don't abort by sending an error as the first param because we'll still show this to the user as "not found"
                return cb null, layerGetData

            #if it was OK though, save the rest
            layerGetData['status'] = 'OK'
            layerGetData['type'] = body.layer.type
            layerGetData['resource'] = body.layer.resource.href

            cb null, layerGetData

getResourceDocumentAsyncMultipleFromGeoserver = (req, res, next) ->
    async.map res.locals.layerData, restGetResourceFromGeoserver, (err, resourceData) ->
        #just propagate errors
        if err?
            return next(err)

        resources = {}
        for resource in resourceData
            #this is a bit of a hack, as there is only 1 key-value pair in the resource. the key can be 'coverage' or 'featureType' or lord knows what
            #hope it doesn't turn out to be important lol. the value of that key then is ALL the data, including name like below
            for key, val of resource
                if val['name']?
                    resources[ val['name'] ] = val
    
        res.locals.resourceData = resources
        # console.log res.locals.resourceData
        next()

restGetResourceFromGeoserver = (layer, cb) ->
    if not layer['resource']?
        return cb null, null
    resourceData = {}
    request
        'method': 'GET'
        'url': layer['resource']
        'json': true
        'auth':
            'user': config.get('geoserver_user')
            'pass': config.get('geoserver_pass')
            'sendImmediately': true
        (err, resp, body) ->
            return cb err if err?
            return cb null, null if resp.statusCode != 200 #don't abort the async by sending a non-null error though, because 404 e.g. is not fatal
            cb null, body #no errors, statusCode == 200