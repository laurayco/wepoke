class @RepeatingFunction
	handle:null
	constructor:(frequency,immediate,callback)->
		@frequency = frequency
		@callback = callback
		if immediate
			@resume()
	pause:()=>
		clearInterval @handle
		@handle = null
	resume:()=>
		@handle = setInterval @callback,@frequency