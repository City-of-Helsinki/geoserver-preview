config = require 'config'
rp = require 'request-promise'
Q = require 'q'


WFS_DOWNLOAD_FORMATS = {'CSV':'CSV', 'GML2':'GML2', 'GML3.1':'text/xml; subtype=gml/3.1.1', 'GML3.2':'application/gml+xml; version=3.2', 'GeoJSON':'application/json', 'KML':'application/vnd.google-earth.kml+xml', 'ShapeFile':'SHAPE-ZIP'}
WMS_DOWNLOAD_FORMATS = {'AtomPub':'atom', 'GIF':'image/gif', 'GeoRSS':'application/rss+xml', 'GeoTIFF':'image/geotiff', 'GeoTIFF 8-bits':'image/geotiff8', 'JPEG':'image/jpeg', 'KML (Compressed)':'application/vnd.google-earth.kmz+xml', 'KML (Network link)': 'application/vnd.google-earth.kml+xml;mode=networklink', 'KML (Plain)':'application/vnd.google-earth.kml+xml', 'PDF':'application/pdf', 'PNG':'image/png', 'PNG 8-bit':'image/png;+mode=8bit', 'SVG':'image/svg', 'Tiff':'image/tiff', 'Tiff 8-bits':'image/tiff8', 'OpenLayers':'text/html;+subtype=openlayers'}

exports.attachHandlers = (app) ->
    #POST
    #nothing here, could be app.post '/layers'

    # GET
    # here we define the serial steps to take when this route is GETted
    app.get '/layers',
        fetchLayers,
        (req, res) ->
            #when we get here, res.locals already has layer and dl-format data
            res.render 'layerlist'


#fetch layers, construct object for template to use when rendering
fetchLayers = (req, res, next) ->
    #parse the layer names
    layerNames = parseQueryParams(req)
    #need to save a reference so we can next() when they're all resolved
    promises = []
    for layerName in layerNames
        url = (config.get 'geoserver_baseurl') + "/rest/layers/#{layerName}"
    
        layerPromise = geoserverRestPromise url
        .then (layer) -> #first document, contains url to full document
            return geoserverRestPromise layer.layer.resource.href
        .then (resourceDoc) -> #full document, contains all data on layer
            #all data is behind either 'coverage' or 'featureType'
            resource = resourceDoc[(Object.keys resourceDoc)[0]]
            layerData =
                'status': 'OK'
                'name': resource['name']
                'namespace': resource['namespace']['name']
                'type': if (Object.keys resourceDoc)[0] == 'coverage' then 'raster' else 'vector'
                'srs': resource['srs']
                'nativeBoundingBox': resource['nativeBoundingBox']
            return layerData
        .catch (error) ->
            layerData =
                'status': 'KO'
                'name': layerName
            return layerData

        promises.push layerPromise

    #allSettled() instead of all() because we don't want to abort on 404
    (Q.allSettled promises).then (results) ->
        res.locals.layerData = []
        results.forEach (result) ->
            res.locals.layerData.push result.value
        res.locals['wfs_formats'] = WFS_DOWNLOAD_FORMATS
        res.locals['wms_formats'] = WMS_DOWNLOAD_FORMATS
        next() #go render

parseQueryParams = (req) ->
    # TODO better error handling
    if not req.query.layers? or req.query.layers == ''
        return []

    req.query.layers.split ','

geoserverRestPromise = (href) ->
    options =
        'method': 'GET'
        'uri': href
        'json': true
        'auth':
            'user': config.get 'geoserver_user'
            'pass': config.get 'geoserver_pass'
            'sendImmediately': true # waiting for contest results in 404
    #turn the request-promise object into a Q promise
    Q (rp options).promise()
