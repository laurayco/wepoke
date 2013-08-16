mergeDictArrayReduceFunc = (sum,part)-> sum[part[0]]=part[1]

class @Syndicator
	#input "signal" ( key or mouse button, for example): [durations]
	# if the duration is negative, key hasn't been lifted yet.
	codes:{}
	connections:[]
	codeOn:(code)=>
		v = 0-Date.now()
		if code of @codes
			@codes[code].push v
		else
			@codes[code]=[v]
		@emitOnSignal code
	codeOff:(code)=>
		v = Date.now()
		if code of @codes
			l = @codes[code]
			if l.length>0
				if l[l.length-1]<0#hasn't yet been released...
					l[l.length-1] += v
					@emitOffSignal code, l[l.length-1], (capture)=>
						if not capture
							@codes[code].pop()
	peek:=>
		r = for keyCode,values in @codes
			if values.length < 1
				continue
			[keyCode,values[0]]
		r.reduce mergeDictArray, {}
		
	pull:=>
		r = for keyCode,values of @codes
			if values.length < 1
				continue
			[keyCode,values.shift()]
		r.reduce mergeDictArray, {}

	emitOffSignal:(code,duration,callback)=>
		for r in (con.handleOff code,duration for con in @connections)
			if r
				callback true
		callback false

	emitOnSignal:(code)=>
		(con.handleOn code for con in @connections)

class @InputEventDelegater#intended to be inherited.
	constructor:(@syndicator)->
	enable:=>
		if not(@ in @syndicator.connections)
			@syndicator.connections.push @
	disable:=>
		if @ in @syndicator.connections
			@syndicator.connections.remove @
	shouldHandleSignal:(code,duration=0)-> true
	handleOff:(code,duration)=>
		if @shouldHandleSignal code,duration
			@handleSignalOff code, duration
	handleOn:(code)=>
		if @shouldHandleSignal code
			@handleSignalOn code
	handleSignalOn:(code)->@
	handleSignalOff:(code,duration)->@

class @CodeGenerator
	constructor:(@syndicator)->
	sendSignal:(code,method)=>
		if method
			@syndicator.codeOn code
		else
			@syndicator.codeOff code

class @Keyboard extends CodeGenerator
	constructor:(syndicator,kbrdsrc=null)->
		super syndicator
		@keyboardSource = kbrdsrc or window
		@keyboardSource.addEventListener 'keydown',@handleKeyDown
		@keyboardSource.addEventListener 'keyup',@handleKeyUp
	handleKeyDown:(event)=> @sendSignal event.keyCode,true
	handleKeyUp:(event)=> @sendSignal event.keyCode,false

class @DemoApp

	class @KeyAlerter extends InputEventDelegater
		handleSignalOff:(code,duration)->
			console.log "Key #{code} was held for #{duration} milliseconds."
			true

	constructor:->
		@syndicator = new Syndicator()
		@keyboard = new Keyboard @syndicator
		@subscriber = new @constructor.KeyAlerter @syndicator
		@subscriber.enable()