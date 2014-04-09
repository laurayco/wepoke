(function(global){
	global.requestAnimFrame = (function(){
		return  global.requestAnimationFrame   || 
			global.webkitRequestAnimationFrame || 
			global.mozRequestAnimationFrame    || 
			global.oRequestAnimationFrame      || 
			global.msRequestAnimationFrame     ||  
			null
	})();
	global.cancelRequestAnimFrame = ( function() {
		return global.cancelAnimationFrame          ||
			global.webkitCancelRequestAnimationFrame    ||
			global.mozCancelRequestAnimationFrame       ||
			global.oCancelRequestAnimationFrame     ||
			global.msCancelRequestAnimationFrame        ||
			null
	} )();
})(this);