/**
*	ACA Secure Kiosk
*	This allows a page designed for user interaction to be displayed securely in an ACA Signage player
*	
*   Copyright (c) 2012 Advanced Control and Acoustics.
*	
*	@author 	Stephen von Takach <steve@advancedcontrol.com.au>
* 	@copyright  2012 advancedcontrol.com.au
*	@version    1.0
**/


(function (window, document) {
		
	var parent = null,
		onInteraction = function(){
			parent.postMessage({message: 5}, '*');			// ELEMENT.touched == 5
		};
	
	window.addEventListener('message', function(event){
		if(event.data['message'] == 0) {					// PLUGIN.hello == 0
			parent = event.source;
			window.addEventListener('mousedown', onInteraction, false);
			window.addEventListener('touchstart', onInteraction, false);
		}
	}, false);
	
})(this, document);
