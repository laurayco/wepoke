
openUrl = ( url, method='GET')->
	req = if XMLHttpRequest? then new XMLHttpRequest() else new ActiveXObject "Microsoft.XMLHTTP"
	req.open(method,url,true)
	req

class @GameLoader

	constructor:(opts)->
		@canvas = opts.gameCanvas
		@game = null
		@currentSave = ko.observable(null)
		@currentSave.subscribe (saveObject)=>
			if saveObject != null and @game == null
				@game = new GamePlay @canvas,@
				@game.play()
		@availableSaves = ko.observableArray([])
		@gameMode = ko.observable("exploring")
		@gameMode.subscribe (newValue)=>
			if @currentSave()==null
				throw {
					type:"LogicFlow"
					message:"You can't set the game mode without an active save."
					detail:newValue
				}
		@currentMode = ko.computed @_currentMode
		@currentMode.subscribe (mode)=>
			if mode == 'loading' or mode =='choosing'
				return
			if @currentSave()==null
				throw {
					type:"LogicFlow"
					message:"You can't change the game mode without an active save."
					detail:newValue
				}
		@database = new GameDatabase()

	_currentMode:=>
		if @currentSave()==null
			if @availableSaves().length < 1
				return "loading"
			else
				return "choosing"
		else
			return @gameMode()

	exploreGame:=>
		if @gameMode()!="exploring"
			@gameMode "exploring"

	chooseSave:(saveData)=>
		@currentSave new GameSave saveData

	startNewGame:=> @chooseSave @defaultSave()

	saveGameState:(save=null,callback=null)=>
		if not (save instanceof GameSave)
			throw {
				type:"LogicFlow"
				message:"You can't save a game that doesn't exist."
				detail:"An attempt to save a non-save object was made."
			}
		@database.saveGame save.exportForSave(),callback

	saveGame:()=>
		@saveGameState @currentSave(),(errors)=>
			if errors==null
				@exploreGame()
			else
				console.log errors

	defaultSave:->
		id:Date.now()
		name:null
		storage:[]
		roster:[]
		inventory:[]
		currency:2000
		location:[]
		position:
			x:0
			y:0
			z:0
			direction:"down"
		variables:{}
		flags:[]

	loadMap:(mapID,callback)=>
		[running,oldMode] = [@game.running,@gameMode()]
		@gameMode "loading"
		if running
			@game.pause
		@database.getMap mapID,(mapObject,errors)=>
			if mapObject!=null
				@gameMode oldMode
				if running
					@game.play
				tileset = new Image()
				tileset.src = "tileset/#{mapObject.tileset}.png"
				tileset.onload = (event)->
					callback mapObject,tileset

	prepare:=>
		@database.prepare (errors)=>
			if errors==null
				#load all saves into @availableSaves.
				allSaves = []
				handleSave = (save)-> allSaves.push save
				finalizeSaves = =>
					if allSaves.length > 0
						@availableSaves(allSaves)
					else
						#if we have none, make a new one!
						@startNewGame()
				@database.readAll "gameSaves",handleSave,finalizeSaves
			else
				console.log errors

class @GameSave
	constructor:(data)->
		@name = ko.observable data.name
		@storage = ko.observableArray data.storage
		@roster = ko.observableArray data.roster
		@inventory = ko.observableArray data.inventory
		@currency = ko.observable data.currency
		@location = ko.observableArray data.location
		@id = data.id
		#position on the loaded map.
		#x = east/west, y = north/south, z = altitude
		@position = data.position
		@gender = data.gender||"m"
	exportForSave:=>
		id:ko.utils.unwrapObservable @id
		name:ko.utils.unwrapObservable @name
		storage:ko.utils.unwrapObservable @storage
		roster:ko.utils.unwrapObservable @roster
		inventory:ko.utils.unwrapObservable @inventory
		currency:ko.utils.unwrapObservable @currency
		location:ko.utils.unwrapObservable @location
		position:@position
		gender:@gender

class @GameDatabase
	iddb:null

	ready:=>return @iddb!=null

	prepare:(cb)->
		[that,request] = [@,indexedDB.open("wepokedb",2)]
		request.onupgradeneeded = @_setupDatabase
		request.onsuccess = (event)=>
			@iddb = event.target.result
			cb(null)
		request.onerror = (event)->
			cb(event)

	_setupDatabase:(event)->
		database = event.target.result
		#adding a saves storage.
		saveStore = database.createObjectStore "gameSaves",{keyPath:"id"}
		pokedexStore = database.createObjectStore "pokedex",{keyPath:"id"}
		mapStore = database.createObjectStore "maps",{keyPath:"id"}

	getMap:(id,cb)=>
		transaction = @iddb.transaction ["maps"],'readwrite'
		mapStore = transaction.objectStore "maps"
		req = mapStore.get id
		beenDone = false
		triggerDownloadMap = ()=>
			if not beenDone
				beenDone = true
				@downloadMap id,(mapObject)->
					cb mapObject
		req.onsuccess = (event)->
			if (event.target.result)?
				cb event.target.result
			else
				triggerDownloadMap()
		req.onerror = ( event ) ->
			console.log event
			triggerDownloadMap()
		null

	downloadMap:(id,cb)=>
		url = openUrl "map/#{id}.json"
		url.send()
		url.onreadystatechange = (event)=>
			if url.readyState == 4
				mapObject = JSON.parse url.responseText
				@storeMap mapObject
				cb mapObject

	storeMap:(map)=>
		transaction = @iddb.transaction ["maps"],'readwrite'
		mapStore = transaction.objectStore "maps"
		mapStore.put map

	saveGame:(save,cb=null)=>
		if cb == null
			cb = (errors)-> console.log errors
		transaction = @iddb.transaction ["gameSaves"],"readwrite"
		saveStore = transaction.objectStore "gameSaves"
		req = saveStore.put(save)
		req.onerror = cb
		req.onsuccess = (event)->
			cb null

	readAll:(store,individualCallback,finalCallback)=>
		transaction = @iddb.transaction [store],"readwrite"
		cursorRequest = transaction.objectStore(store).openCursor()
		cursorRequest.onsuccess = (event)->
			if event.target.result==null
				finalCallback()
			else
				individualCallback event.target.result.value
				event.target.result.continue()

@knockoutSetup = (settings)->
	thing = new GameLoader(settings)
	thing.prepare()
	ko.applyBindings thing
	thing

@resetDatabase = ->
	indexedDB.deleteDatabase("wepokedb")