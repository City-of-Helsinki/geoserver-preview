exports.attachHandlers = (app) ->

	#pass the app instance to all routes that need routing here.
	(require './layers/layers').attachHandlers app