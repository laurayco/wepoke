class OverworldControls

	class MenuHandler extends InputEventDelegater
		@minHold:100#must hold the button at least 100ms.
		@openMenu:16
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

	constructor:(@player,@gameInterface)->
		@syndicator = new Syndicator()
		@keyboard = new Keyboard @syndicator
		@menuHandler = new MenuHandler @syndicator,@
	
	enable:=>
		@menuHandler.enable()
	disable:=>
		@menuHandler.disable()

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