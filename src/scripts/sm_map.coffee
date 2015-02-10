sm_leaflet_map = (element) ->
    sm_crs_name = 'EPSG:3067'
    sm_proj_def = '+proj=utm +zone=35 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'
    # sm_bounds = [25440000, 6630000, 25571072, 6761072]
    sm_bounds = L.bounds L.point(-548576, 6291456), L.point(1548576, 8388608)
    origin_nw = [sm_bounds.min.x, sm_bounds.max.y]
    # sm_crs = new L.Proj.CRS.TMS sm_crs_name, sm_proj_def, sm_bounds,
        # resolutions: [256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625]
    crs_opts =
        resolutions: [8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25]
        bounds: sm_bounds
        transformation: new L.Transformation 1, -origin_nw[0], -1, origin_nw[1]
    sm_crs = new L.Proj.CRS sm_crs_name, sm_proj_def, crs_opts

    sm_layer_name = "osm-sm/etrs_tm35fin"
    sm_layer_fmt = "png"
    sm_layer = new L.tileLayer "http://geoserver.hel.fi/mapproxy/wmts/osm-sm/etrs_tm35fin/{z}/{x}/{y}.png",
        maxZoom: 15
        minZoom: 6
        continuousWorld: true
        tms: false

    map = new L.Map element,
        crs: sm_crs
        continuusWorld: true
        worldCopyJump: false
        zoomControl: true
        attribution: "Servicemap" #TODO
        layers: [sm_layer]
    map.setView [60.171944, 24.941389], 13

    L.control.scale(imperial: false, maxWidth: 200).addTo map

    layer_control = L.control.layers
        'Palvelukartta': sm_layer

    return map: map, layer_control: layer_control


exports.sm_map = sm_leaflet_map