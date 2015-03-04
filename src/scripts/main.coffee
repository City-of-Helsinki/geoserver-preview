#this is the main file that pulls in all other modules

@olmap = (require "./olmap").MapObj
map = @olmap.createMap('map')

# Event handlers for "toggle visibility"
((mapObj) ->
    ($ '.layerToggle').on 'click', (event) ->
        targ = $ event.target
        name = ($ targ[0]).data 'name'
        namespace = ($ targ[0]).data 'namespace'
        layername = "#{namespace}:#{name}"
        opacity = ($ ($ ($ targ[0]).parent().siblings '#opacity').find 'input').val() / 100

        # should we show the layer or hide it?
        if targ.hasClass 'do-show'
            (targ.removeClass 'do-show').addClass 'do-hide'
            targ.html 'Hide'

            # only fetch from server if we havent' already
            if not mapObj.layers[name]?
                #TODO don't hardcode the base address
                url = "http://geoserver.hel.fi/geoserver/#{namespace}/wms"
                newlayer = new ol.layer.Image
                    opacity: opacity
                    source: new ol.source.ImageWMS
                        url: url
                        params:
                            VERSION: '1.1.0'
                            LAYERS: layername
                        serverType: 'geoserver'
                # after fetching, add it to the mapobject's layers list/object
                mapObj.layers[name] =
                    'layerObj': newlayer
                    'styles': []

            # we've either fetched the image and created a layer just now or earlier. either way it should be there 
            mapObj.layers[name]['layerObj'].setOpacity opacity
            mapObj.map.addLayer(mapObj.layers[name]['layerObj'])
        
        else
            (targ.removeClass 'do-hide').addClass 'do-show'
            targ.html 'Show'
            mapObj.map.removeLayer mapObj.layers[name]['layerObj'])(@olmap)
