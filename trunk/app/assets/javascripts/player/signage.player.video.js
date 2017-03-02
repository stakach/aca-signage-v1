


var VideoPlayer = (function($, global) {
	
	var displayMan,
		settings,
		
		exclusiveLevel = -1,		
		playlist,			// The current playlist
		media,				// The list of media items (false, )
		
		previous,
		current,
		next,
		index = -1,				// Current play list item
		currentElement = null,	// The actual element to be played
		nextElement = null,		// The next element to be played
		previousElement = null,	// The previous element (if not destroyed)
		effect = null,			// The effect to be used during the transition
		
		newList = false,		// We were in a transition when the new list arrived, we should change to it.
		doLoadNext = false,		// If loaded is called during a transition
		restarting = false;
		
	//
	// Wait for jQuery to load
	//
	$(function() {
		
		current = $('article:last-child');
		previous = $('article:first-child');
		next = previous.next('article');
		
	});
	
	
	//
	// This handles the new data being received after an update
	//
	function applyListUpdate(data) {
		var instant = newList;			// Two updates in the period of a transition? Unlikely, we'll handle it though :)
		
		if(restarting)					// Handle concurrency
			return;
		
		media = data.media;
		playlist = data.playlist;
		
		if(exclusiveLevel != data.exclusive) {
			exclusiveLevel = data.exclusive;
			instant = true;
		}
			
		if(index >= playlist.length || data.restart || instant)
			index = 0;
		
		if (global.transitioning) {
			if(instant)
				newList = true;						// Flag that a new list is ready after the transition
			else
				newList = false;
		} else {
			newList = false;
			
			if(currentElement == null || instant)	// If we are not playing we should start
				instantNext();
			else {
				if (nextElement != null)
					previousItem();
				prepareNext();
			}
		}
	}
	
	
	//
	// This effectively resets the player
	//
	function instantNext() {
		//
		// Ensure offscreen elements are destroyed
		//
		if(previousElement != null) {
			previousElement.destroy();
			previousElement = null;
		}
		
		if(nextElement != null) {
			nextElement.destroy();
			nextElement = null;
		}
		
		//
		// Blank the screen and destroy current element offscreen
		//
		if(currentElement != null) {
			previous.html('<div />').removeClass('previous');		// Previous should have been destroyed at this point
			current.html('<div />').prependTo(current.parent()).addClass('previous');
			
			current = $('article:last-child');
			previous = $('article:first-child');
			next = previous.next('article').html('<div />');
			
			currentElement.destroy();
			currentElement = null;
		}
		
		//
		// Prepare the next element if there is a next - otherwise we'll just hang on black :)
		//
		index = -1;
		if(playlist.length > 0)
			prepareNext();
		else
			displayMan.canRestart();
	}
	
	
	//
	// This loads up the next element for playback
	//	If the currentElement is null we will transition as soon as possible (delay 0?)
	//
	function prepareNext(){
		if(nextElement != null) {
			if (!!effect.cancel)
				effect.cancel();
			nextElement.destroy();
			nextElement = null;
		}
		
		nextItem();
		
		if(playlist.length > 0) {
			var play = playlist[index],
				item = media[play.media];
				
			nextElement = loadElement(next.html('<div />').children().css('background-color', item.background), item, {timeout: play.pub_run_time});
			nextElement.subscribe(nextCallback);
			effect = new Effect(current, next, play.pub_transition_effect, effectComplete);
		} else {						// if there was no playlist
			if(!!currentElement)		// if there is still a current element
				effect = new Effect(current, next, 0, effectComplete);	// Fade to black
			index = -1;
			nextElement = null;
		}
	}
	
	
	function nextItem() {
		index += 1;
		if(index >= playlist.length) {
			if(displayMan.canRestart('video') || restarting == true) {
				playlist = [];
				restarting = true;
			}
			else
				index = 0;
		}
	}
	
	function previousItem() {
		index -= 1;
		if(index <= 0)
			index = playlist.length - 1;
	}
	
	
	//
	// If the element has something to say while it is not displayed
	//	We really only care about it's error state
	//
	function nextCallback(signal, message, reason) {
		switch(signal) {
			case ELEMENT.error:		// There was a load error while setting up the next media item
				prepareNext();
				if (global.transitioning)
					currentComplete();
				//
				// TODO:: inform display of the error
				//
				
				break;
			case ELEMENT.ready:
				if (currentElement == null) {		// So nothing is playing right now...
					currentComplete();
				}
				break;
			case ELEMENT.loaded:
				doLoadNext = true;
		}
	}
	
	
	function currentCallback(signal, message, reason) {
		if (!global.transitioning) {	// We ignore all signals while transitioning TODO:: should remove these before the transition
			switch(signal) {
				case ELEMENT.error:		// There was a error during playback
					//
					// TODO:: inform display of the error
					//
				case ELEMENT.ended:		// NOTE:: we want to fall through
					currentComplete();
					break;
				case ELEMENT.loaded:
					prepareNext();
			}
		}
	}
	
	
	function currentComplete() {
		if(nextElement == null)
			prepareNext();
		
		global.transitioning = true;
		setTimeout(effect.transition, 100);
	}
	
	
	function effectComplete() {
		//
		// Swap next and current elements (including callbacks)
		//
		previousElement = currentElement;
		currentElement = nextElement;
		nextElement = null;
		effect = null;
		
		
		if(previousElement != null) {
			previousElement.unsubscribe(currentCallback);
			previousElement.destroy();
		}
		
		
		//
		// Update DOM references
		//
		current = $('article:last-child');
		previous = $('article:first-child');
		next = previous.next('article');
		
		next.removeClass('previous');
		previous.addClass('previous');
		
		
		
		if(currentElement == null) {
			if(restarting) {
				displayMan.readyRestart('video');
			} else if (newList) {
				newList = false;
				instantNext();
			}
		} else {
			currentElement.unsubscribe(nextCallback);
			currentElement.subscribe(currentCallback);
			
			
			//
			// Check if a new playlist was downloaded
			//
			if (newList) {
				newList = false;
				instantNext();
			} else {
				//
				// Check for any errors that may have occured during the transition
				//
				switch(currentElement.status()) {
					case ELEMENT.error:
					case ELEMENT.ended:
						//
						// TODO:: move to the next element quick smart!
						//
						break;
					default:
						currentElement.play();	// Play otherwise
						if (doLoadNext) {
							prepareNext();
						}
				}
				
				doLoadNext = false;
			}
		}
	}
	
	
	
	return function(audioPlayer) {
		
		this.downloaderMessage = function(data) {
			data = data.data;
			switch(data.message){
				case SIG.new_list:
					applyListUpdate(data);
			}
		};
		
		this.displayMessage = function(data){
			switch(data.message){
				case SIG.hello:				// Display is giving us a reference to itself
					displayMan = data.from;
					break;
				case SIG.restart:				// Display wants to know when we can restart (end of current item)
					restarting = true;
					if(currentElement == null && !global.transitioning)
						displayMan.readyRestart('video');
					break;
				case SIG.supports:
					settings = data.settings;
					//
					// TODO:: apply these settings
					//
			}
		};
	};
	
})(jQuery, this);

