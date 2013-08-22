class @RepeatingFunction
	constructor:(@frequency,immediate,@callback)->
		if immediate
			@resume()
	pause:()=>
		clearInterval @handle
		@handle = null
	resume:()=>
		@handle = setInterval @frequency,@callback