class @ScriptCommand
	@parameters:{}
	@name:"nop"
	constructor:(parameters)->
		reqd = (param for param,v in @constructor.parameters if v.required)
		for req in reqd
			if not req of parameters
				throw 
					message:"Not all of your required parameters are there."
		@parameters = Object.merge @constructor.parameters, parameters, true
	startCommand:(hero,map,iface)=>
		@finishCommand hero, map, iface
	finishCommand:(hero,map,iface)=>
		iface.advance hero, map

class @MessageCommand extends ScriptCommand
	@parameters:
		image:
			default:null
			optional:true
		message:
			default:null
			optional:false
		type:
			default:"statement"
			optional:true
	@name:"msg"
	startCommand:
		iface.messages.push new MessageLog @parameters

class @CommandChain
	constructor:(builtScript)->
		@build = builtScript
		@_currentCommand = 0
	advance:()=>
		@_currentCommand++
		@currentCommand().start()
		@currentCommand().end @advance
	currentCommand:()=>return @build.commands[@_currentCommand]

class @ScriptParser
	@identify:(sourceCode)=>
		# find all script labels.
		# include their contents in .code
		# label_name
		# [indent]code
		# also, store constants in .constants as {constant:value}
		# $constant = Species.Bulbasaur
		# $constant = 4
		# $constant = "Text"
		# $constant = Flag.HasPokemonMenuEnabled
		# $constant = Variable.StarterPokemon
		sourceCode
	@parse:(identified)=>
		# parse all commands
		# delete .code, store parsed command calls in .meta
		# store the propar command class in eacch .meta[].command
		# command_name argumentOne, argumentTwo, argumentThree, kwargName = argumentFive
		identified
	@compile:(parsed)=>
		# create command objects in from information in .meta[]
		# store command objects in .commands
		parsed
	@build:(compiled)=>
		# build execution chain for each .commands[]
		# store chain in .execute
		# delete .meta[]
		compiled