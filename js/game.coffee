class OverworldControls

	class MenuHandler extends InputEventDelegater
		@minHold:100#must hold the button at least 100ms.
		@openMenu:16
		@openInventory:69
		@openRoster:81
		constructor:(syndicator,owc)->
			super syndicator
			@overworldInterface = owc
		shouldHandleSignal:(code,duration)->
			if duration >= @constructor.minHold
				code == @constructor.openMenu
			else
				false
		handleSignalOff:(signal)->
			if signal == @constructor.openMenu
				@overworldInterface.openMenu()

	class MovementHandler extends InputEventDelegater
		@moveCodes = 
			65:"left"
			87:"up"
			83:"down"
			68:"right"
		@holdRunning:32
		@minHold:30
		@currentDirection:null
		@running:false

		constructor:(syndicator,owc)->
			super syndicator
			@overworldInterface = owc

		shouldHandleSignal:(code,duration)=>
			code of @constructor.moveCodes or code is @constructor.holdRunning

		handleSignalOn:(signal)=>
			if signal of @constructor.moveCodes
				direction = @constructor.moveCodes[signal]
				if @currentDirection is null
					@startMovement @constructor.moveCodes[signal]
				else if @currentDirection isnt direction
					@changeMovement @constructor.moveCodes[signal]
			else if signal == @constructor.holdRunning and not @running
				console.log "Now running"
				@running = true

		handleSignalOff:(signal)=>
			if signal of @constructor.moveCodes
				if @constructor.moveCodes[signal] == @currentDirection
					@currentDirection = null
					@endMovement()
			else if signal == @constructor.holdRunning and @running
				console.log "No longer running."
				@running = false

		startMovement:(direction) =>
			console.log "Moving:",@currentDirection = direction

		changeMovement:(direction) =>
			console.log "New Direction:",@currentDirection = direction

		endMovement:()=>
			console.log "Done moving."

	constructor:(@player,@gameInterface)->
		@syndicator = new Syndicator()
		@keyboard = new Keyboard @syndicator
		@menuHandler = new MenuHandler @syndicator,@
		@movementHandler = new MovementHandler @syndicator,@
	
	enable:=>
		@menuHandler.enable()
		@movementHandler.enable()

	disable:=>
		@menuHandler.disable()
		@movementHandler.disable()

	openMenu:=> @gameInterface.gameMode "saving"

class @GamePlay
	running:false
	handle:null
	constructor:(@canvas,@interface)->
		@overworldResponse = new OverworldControls null,@interface
	getSave:(cb)=>cb(@interface.currentSave())
	loadedMap:null
	tileset:null
	play:=>
		if @loadedMap == null
			@interface.loadMap 1,(map,tileset)=>
				@loadedMap = map
				@tileset = tileset
				@running = true
				@requestFrame @frame
		else
			@running=true
			@requestFrame @frame
		@overworldResponse.enable()
	frame:=>
		#do things per-frame here. yup.
		[width,height]=[32,32]
		[boundsW,boundsH]=[@canvas.width-width,@canvas.height-height]
		[xpos,ypos] = [(Number.random boundsW),(Number.random boundsH)]
		context = @canvas.getContext "2d"
		context.clearRect 0,0, @canvas.width, @canvas.height
		frame = 0
		for layer in @loadedMap.layers
			[mapx,mapy]=[0,0]
			for tile in layer
				if tile>=0
					[tilex,tiley,tileWidth,tileHeight] = @getTileSlice tile,frame
					[blitX,blitY] = [mapx*tileWidth,mapy*tileHeight]
					context.drawImage @tileset,tilex,tiley,tileWidth,tileHeight,blitX,blitY,tileWidth,tileHeight
				if ++mapx>=@loadedMap.width
					mapy+=1
					mapx=0
	getTileSlice:(tileNumber)=>
		return [tileNumber * 16, 0, 16, 16 ]
	pause:(halt=false)=>
		@overworldResponse.disable()
		if halt
			if requestAnimationFrame != null
				cancelRequestAnimFrame @handle
			else
				clearTimeout @handle
		@running = false
	requestFrame:(cb)=>
		if requestAnimationFrame != null
			@handle = requestAnimFrame cb
		else
			@handle = setTimeout cb,1000/64