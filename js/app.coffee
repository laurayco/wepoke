
class Log
	constructor: (@message)->
		@priority = 1
		@created = Date.now()
		@expires = 5 * 1000
	get_text: ()=>
		return "[#{@created}:] @message"

class DebugLog extends Log
	constructor: (message)->
		super message
		@priority = 2
		@expires = 5 * 1000

module = angular.module "WePoke", ["ngAnimate"]

module.constant "NewGame",
	created: Date.now()
	name: null
	gender: null
	roster: [] # indexes referring to storage.
	storage: [] #all pokemons.
	boxes: [] # [ [index] ]
	emblems: []

module.factory "GlobalEvents", ($window)->
	meta_events =
		network_click: ()->
			$window.alert "Opening network navigation..."
		log:(message)-> new Log(message)
		debug:(message)-> new DebugLog(message)
	listeners = {}
	event_connection =
		listen: (event,handler)->
			key = 0 # generate random thing.
			lis = listeners[event]
			if lis?
				lis[key] = handler
			else
				listeners[event] = {}
				listeners[event][key] = handler
			key
		ignore: (event,key)->
			lis = listeners[event]
			del lis[key]
			null
		handle: (event)->
			return meta_events[event]

module.factory "GameSave", ($q,NewGame)->
	save_data = null
	internal =
		make_new_game: ()->
			promise = $q.defer()
			data =
			promise.promise
	manager =
		load_game: ()->
			promise = $q.defer()
			set_game = (game)->
				promise.resolve(save_data = game)
			if save_data?
				set_game(save_data)
			else
				internal.make_new_game().then(set_game)
			promise.promise

module.factory "ScriptEngine", ($q,$http,GlobalEvents)->
	environment =
		init:(save)->
			game_save = save
		load_script:(name)->
			script_load = null
			start_script = ()->
				null
			script_load.then start_script
	environment

module.controller "Game", ($scope,GameSave,ScriptEngine,GlobalEvents)->
	$scope.save = null
	$scope.message_log = []
	GlobalEvents.listen
	start_game = (save)->
		$scope.save = save
		ScriptEngine.init $scope.save
	GameSave.load_game().then start_game

module.controller "Navigation", ($scope,GlobalEvents)->
	$scope.menu_items = [
		{
			text:"Network",
			icon:"favicon.ico",
			action:"network_click"
		}
	]
	$scope.handle_event = GlobalEvents.handle
	null
