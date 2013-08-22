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
		direction:null

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
			else if signal == @constructor.holdRunning and not @overworldInterface.game.heroEntity.running
				console.log "Now running"
				@overworldInterface.game.heroEntity.running = true

		handleSignalOff:(signal)=>
			if signal of @constructor.moveCodes
				if @constructor.moveCodes[signal] == @currentDirection
					@currentDirection = null
					@endMovement()
			else if signal == @constructor.holdRunning and @overworldInterface.game.heroEntity.running
				console.log "No longer running."
				@overworldInterface.game.heroEntity.running = false

		startMovement:(direction) =>
			@currentDirection = direction
			@overworldInterface.game.heroEntity.startMoving @currentDirection

		changeMovement:(direction) =>
			@currentDirection = direction
			@overworldInterface.game.heroEntity.changeDirection @currentDirection

		endMovement:()=>
			@overworldInterface.game.heroEntity.stopMoving()

	constructor:(@player,@gameInterface,@game)->
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

class @OverworldEntity
	position:
		x:ko.observable 0
		y:ko.observable 0
	sprite:null
	direction:"down"
	speedMultiplier:1.0#if you start running, this will slowly progress towards
	@maxSpeedPeek:3.0# this value here. Releasing the RUN button will slowly go
	# bring the speed multiplier back down to 1.0, or if you quit moving altogether
	# then speedMultiplier will automatically go back to 1.0
	nextStepCompletion:0#range between 0 and 100 as percentage.
	running:false
	stepTimer:null
	constructor:(cls,onLoad=null)->
		if onLoad is null
			onLoad = ()->null
		@spriteClass = cls
		@stepTimer = new RepeatingFunction 100, false, @advanceStep
		OverworldSprite.loadSprite @spriteClass,(spr)=>
			@sprite = spr
			onLoad @sprite
	render:(context,tw,th)=>
		directionalMultiplier = 0
		if @nextStepCompletion > 0
			directionalMultiplier = {'left':tw,'right':tw,'up':th,'down',th}
			directionalMultiplier = directionalMultiplier[@direction]
		sf = Math.floor (@nextStepCompletion/100.0*directionalMultiplier)
		@sprite.render context,@position.x(),@position.y(),@direction,sf,tw,th
	startMoving:(direction)=>
		@direction = direction
		@stepTimer.resume()
	changeDirection:(direction)=>
		@direction = direction
		@speedMultiplier = 1.0
		@roundStep()
	roundStep:()=>
		if @nextStepProgress >= 50
			@confirmStep()
		else
			@resetStep()
	advanceStep:()=>
		#@getTargetPosition (targetPosition)=>
		#	if targetPosition.x < 0
		#		@resetStep()
		#		@stopMoving()
		#	if targetPosition.y < 0
		#		@resetStep()
		#		@stopMoving()
		console.log @nextStepCompletion += 10
	resetStep:()=>
		@nextStepCompletion = 0
	confirmStep:()=>
		if direction=='left'
			position.x position.x()-1
		else if direction=='right'
			position.x position.x()+1
		else if direction=='up'
			position.y position.y()-1
		else if direction=='down'
			position.y position.y()+1
		resetStep()
	stopMoving:()=>
		@roundStep()
		@speedMultiplier = 1.0
		@stepTimer.pause()

class @HeroEntity extends OverworldEntity
	constructor:(saveInfo,onLoad=null)->
		if onLoad is null
			onLoad = ()->null
		super "hero_#{saveInfo.gender}", onLoad
		@saveInfo = saveInfo
		@position = @saveInfo.position

class @OverworldSprite
	@cache:{}

	@loadSprite:(cls,cb)=>
		if cls of @cache
			cb @cache[cls]
		else
			new OverworldSprite cls,(sprite)=>
				cb @cache[cls] = sprite

	constructor:(@overworldClass,cb)->
		@image = new Image()
		@image.src = "overworld/#{@overworldClass}.png"
		@image.onload = (event)=> cb @

	render:(context,x,y,direction,frameStep,tw,th)=>
		# x / y = map position of sprite BEFORE frameStep is considered.
		# direction = up / down / left / right ( which way sprite is facing )
		# frameStep = percentage ( 0 - 100 ) of how near the sprite is to next step.
		# tw / th = tile width / tile height. used for centering purposes.
		[blitX,blitY] = [x*tw,y*th]
		[spriteWidth,spriteHeight] = [parseInt(@image.width)/ 4,parseInt(@image.height)/3]
		if @image.width > tw
			blitX -= ((spriteWidth - tw ) / 2)
		if spriteHeight > th
			blitY -= (spriteHeight - th)
		blitX += Math.floor (frameStep / 3.0 * tw)
		animationFrame = 0
		frameStep -= 34
		while frameStep > 0
			animationFrame += 1
			frameStep -= 34
		frames =
			"down":0
			"up":1
			"left":2
			"right":3
		[sliceX,sliceY] = [frames[direction] * spriteWidth,animationFrame * spriteHeight]
		context.drawImage @image,sliceX,sliceY,spriteWidth,spriteHeight,blitX,blitY,spriteWidth,spriteHeight

class @GamePlay
	running:false
	handle:null

	@tileWidth:16
	@tileHeight:16

	constructor:(@canvas,@interface)->
		@overworldResponse = new OverworldControls null,@interface,@
		@interface.currentSave()

	getSave:(cb)=>cb @interface.currentSave()

	loadedMap:null
	tileset:null
	heroEntity:null

	play:=>
		allowPlay = ()=>
			@running = true
			@overworldResponse.enable()
			@requestFrame @frame
			true
		
		[mapLoaded,playerLoaded] = [not (@tileset is null or @loadedMap is null),not @heroEntity is null]
		checkBack = ()=>
			if mapLoaded and playerLoaded
				allowPlay()
			else
				false
		if not checkBack()
			if not mapLoaded
				@interface.loadMap 1,(mapObject,tileset)=>
					@loadedMap = mapObject
					@tileset = tileset
					mapLoaded = true
					checkBack()
			if not playerLoaded
				@getSave (saveInfo)=>
					@heroEntity = new HeroEntity saveInfo,()=>
						playerLoaded = true
						checkBack()

	frame:=>
		#do things per-frame here. yup.
		@getSave (save)=>
			[playerSpriteWidth,playerSpriteHeight] = [16,32]
			[playerPositionX,playerPositionY] = [save.position.x(),save.position.y()]
			[width,height]=[16,16]
			[boundsW,boundsH]=[@canvas.width-width,@canvas.height-height]
			[xpos,ypos] = [(Number.random boundsW),(Number.random boundsH)]
			[cameraAdjustX,cameraAdjustY] = [@canvas.width/2,@canvas.height/2]
			cameraAdjustX -= playerPositionX * width#adjust for the player's x position
			cameraAdjustY -= playerPositionY * height#adjust for the player's y position
			cameraAdjustX -= Math.abs (playerSpriteWidth - width) / 2
			context = @canvas.getContext "2d"
			context.clearRect 0,0, @canvas.width, @canvas.height
			context.setTransform 1,0,0,1,cameraAdjustX,cameraAdjustY
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
			@drawOverworlds context
			@requestFrame @frame
			null

	startPlayerMovement:(direction)=>
		null

	endPlayerMovement:()=>
		null

	changePlayerMovement:(direction)=>
		null

	drawOverworlds:(context)=>
		for ow in @getOverworlds true
			ow.render context, @constructor.tileWidth, @constructor.tileHeight

	getOverworlds:(includeHero)=>
		r = if includeHero then [@heroEntity] else []
		#bring in the others from the map.
		#eventually. maybe. meh.

	getTileSlice:(tileNumber)=>
		return [tileNumber * @constructor.tileWidth, 0, @constructor.tileWidth, @constructor.tileHeight ]

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