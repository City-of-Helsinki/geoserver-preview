orto_leaflet_map = (element) ->
    orto_crs_name = 'EPSG:3879'
    orto_proj_def = '+proj=tmerc +lat_0=0 +lon_0=25 +k=1 +x_0=25500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'
    orto_bounds = [25440000, 6630000, 25571072, 6761072]
    orto_crs = new L.Proj.CRS.TMS orto_crs_name, orto_proj_def, orto_bounds,
        resolutions: [256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625]

    orto_layer_name = "hel:orto2013"
    orto_layer_fmt = "jpg"
    orto_layer = new L.Proj.TileLayer.TMS "http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/#{orto_layer_name}@ETRS-GK25@#{orto_layer_fmt}/{z}/{x}/{y}.#{orto_layer_fmt}", orto_crs,
        maxZoom: 11
        minZoom: 2
        continuousWorld: true
        tms: false

    map = new L.Map element,
        crs: orto_crs
        continuusWorld: true
        worldCopyJump: false
        zoomControl: true
        layers: [orto_layer]
    map.setView [60.171944, 24.941389], 7

    L.control.scale(imperial: false, maxWidth: 200).addTo map

    layer_control = L.control.layers
        'Ilmakuva': orto_layer

    return map: map, layer_control: layer_control


# createmap = () ->	
# 	map = (L.map 'map').setView [60.101, 24.561], 13
# 	# (L.tileLayer 'http://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
# 	# 	attribution:'ASDF'
# 	# 	maxZoom:18).addTo map
# 	(L.tileLayer 'http://geoserver.hel.fi/mapproxy/osm-sm/etrs_tm35fin/{z}/{x}/{y}.png',
# 	    maxZoom: 15
# 	    minZoom: 6
# 	    continuousWorld: true
# 	    tms: false).addTo map

# 	map

# exports.hellomap = () ->
# 	# ($ 'document').ready console.log 'Hello I am ready'
# 	($ 'document').ready createmap()

exports.orto_map = (element) ->
	orto_leaflet_map(element)