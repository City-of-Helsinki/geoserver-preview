config = require 'config'
parseString = require('xml2js').parseString
rp = require 'request-promise'
Q = require 'q'


WFS_DOWNLOAD_FORMATS = {'CSV':'CSV', 'GML2':'GML2', 'GML3.1':'text/xml; subtype=gml/3.1.1', 'GML3.2':'application/gml+xml; version=3.2', 'GeoJSON':'application/json', 'KML':'application/vnd.google-earth.kml+xml', 'ShapeFile':'SHAPE-ZIP'}
WMS_DOWNLOAD_FORMATS = {'AtomPub':'atom', 'GIF':'image/gif', 'GeoRSS':'application/rss+xml', 'GeoTIFF':'image/geotiff', 'GeoTIFF 8-bits':'image/geotiff8', 'JPEG':'image/jpeg', 'KML (Compressed)':'application/vnd.google-earth.kmz+xml', 'KML (Network link)': 'application/vnd.google-earth.kml+xml;mode=networklink', 'KML (Plain)':'application/vnd.google-earth.kml+xml', 'PDF':'application/pdf', 'PNG':'image/png', 'PNG 8-bit':'image/png;+mode=8bit', 'SVG':'image/svg', 'Tiff':'image/tiff', 'Tiff 8-bits':'image/tiff8', 'OpenLayers':'text/html;+subtype=openlayers'}
ENDPOINT_BASEURL = config.get 'base_url'
geoserverBaseUrl = config.get 'geoserver_baseurl'

exports.attachHandlers = (app) ->
    # GET
    # here we define the serial steps to take when this route is GETted
    app.get ENDPOINT_BASEURL,
        fetchLayers,
        (req, res) ->
            #when we get here, res.locals already has layer and dl-format data
            res.render 'layerlist'

#promises to overcome asynchness of requests and xml parsing, just extracts the names of the layers
capabilitiesToLayerList = (url) ->
    Q (rp url).then (capabilitiesDocument) ->
        (Q.nfcall parseString, capabilitiesDocument).then (jsonCapabilities) ->
            layers = jsonCapabilities['WMS_Capabilities']['Capability'][0]['Layer'][0]['Layer']
            namelist = (layer['Name'][0] for layer in layers)
            return namelist

#fetch layers, construct object for template to use when rendering
fetchLayers = (req, res, next) ->

    if !geoserverBaseUrl || ((typeof geoserverBaseUrl) == "undefined") || (geoserverBaseUrl.length == 0)
        next()

    #parse the layer names
    layerNames = parseQueryParams(req)
    if not layerNames.length
        #even if nothing was requested, show at least something
        return res.redirect(ENDPOINT_BASEURL + '?layers=Seutu_tilastoalueet')

    #need to store because we need to know when all of the promises are done
    promises = []

    #promise to fetch all layer names from the capability document to show as list
    allLayersListPromise = capabilitiesToLayerList(geoserverBaseUrl + '/ows?service=wms&version=1.3.0&request=GetCapabilities')
    promises.push(allLayersListPromise)

    #then construct the promises that return the individual layer documents
    for layerName in layerNames
        url = geoserverBaseUrl + "/rest/layers/#{layerName}"
        layerPromise = geoserverRestPromise url
        .then (layer) -> #first document, contains url to full document
            return geoserverRestPromise layer.layer.resource.href
        .then (resourceDoc) -> #full document, contains all data on layer
            #all data is behind either 'coverage' or 'featureType'
            resource = resourceDoc[(Object.keys resourceDoc)[0]]
            type = if (Object.keys resourceDoc)[0] == 'coverage' then 'raster' else 'vector'
            layerData =
                'status': 'OK'
                'name': resource['name']
                'namespace': resource['namespace']['name']
                'type': type
                'srs': resource['srs']
                'nativeBoundingBox': resource['nativeBoundingBox']
                'downloadLinks': makeDownloadLinks(resource)
            return layerData
        .catch (error) ->
            layerData =
                'status': 'KO'
                'name': layerName
            return layerData

        #store the promise we just constructed
        promises.push layerPromise

    #allSettled() instead of all() because we don't want to abort on 404
    (Q.allSettled promises).then (results) ->
        #first element is the list of all layers
        res.locals['available_layers'] = results[0].value

        res.locals.layerData = []
        results.slice(1).forEach (result) ->
            res.locals.layerData.push result.value
        res.locals['wfs_formats'] = WFS_DOWNLOAD_FORMATS
        res.locals['wms_formats'] = WMS_DOWNLOAD_FORMATS
        next() #go render

parseQueryParams = (req) ->
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

makeDownloadLinks = (resource) ->
    commonUrl = geoserverBaseUrl + '/' + resource['namespace']['name']
    layerFullName = resource['namespace']['name'] + ':' + resource['name']
    bboxStr = "#{resource['nativeBoundingBox']['minx']},#{resource['nativeBoundingBox']['miny']},"+
        "#{resource['nativeBoundingBox']['maxx']},#{resource['nativeBoundingBox']['maxy']}"

    wms_url = commonUrl + "/wms?service=WMS&version=1.1.0&request=GetMap"+
        "&layers=#{layerFullName}"+
        "&styles=&bbox=#{bboxStr}"+
        "&width=512&height=411"+
        "&srs=#{resource['srs']}"+
        "&format="

    wfs_url = commonUrl + "/ows?service=WFS&version=1.0.0&request=GetFeature"+
        "&typeName=#{layerFullName}"+
        "&maxFeatures=1000000"+
        "&outputFormat="

    return {'wms': wms_url, 'wfs': wfs_url}
