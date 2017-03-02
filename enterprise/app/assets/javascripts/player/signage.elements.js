//
// TODO:: Define this as a AMD module
//
var loadElement = (function($, global) {
	
	function PluginElement(parent, media, options) {	// Timeout optional
		options = $.extend({
			ignore_timeout: false,		// Allow for previewing
			controls: false				// Prevent pausing
		}, options || {});
		
		var state = {
			callbacks: $.Callbacks(),
			status: ELEMENT.loading,
			autoplay: false,
			// element
			// timer
			
			play: function() {
				//
				// Trigger play
				//
				state.status = ELEMENT.playing
				state.element[0].contentWindow.postMessage({message:PLUGIN.play}, '*');
				
				//
				// Start timer if required
				//
				if(!!options.timeout) {
					state.timer = setTimeout(state.time_up, options.timeout);
				}
			},
			receive_message: function(event) {
				//
				// Ensure we are chatting to the correct iFrame (can be multiple loaded)
				//
				if(event.originalEvent.source != state.element[0].contentWindow)
					return;
					
				var data = event.originalEvent.data;
					
				//
				// Process the response
				//
				switch(data.message) {
					case ELEMENT.ready:
						if(!!state.load_timer){
							clearTimeout(state.load_timer);
							delete state.load_timer;
						}
						state.status = data.message;
						state.callbacks.fire(data.message);
						if(state.autoplay)
							state.play();
						break;
					case ELEMENT.ended:
						state.status = data.message;
						state.callbacks.fire(ELEMENT.loaded);
						state.callbacks.fire(data.message);
						break;
					case ELEMENT.error:
						state.status = ELEMENT.ended;
						state.callbacks.fire(ELEMENT.loaded);
						state.callbacks.fire(data.message, ERROR.plugin, data.reason);
						break;
					case ELEMENT.touched:
						//
						// TODO:: Add a secondary timer
						//	If first timer goes off while this timer is active we ignore
						//	Cancel any existing touched timer and start again
						//	We need to be able to count these too
						//
						break;
					case ELEMENT.loaded:
						state.callbacks.fire(data.message);
						break;
					default:	// Unsupported message
						return;
				}
			},
			time_up: function(){
				delete state.timer;
				state.status = ELEMENT.ended;
				state.element[0].contentWindow.postMessage({message:PLUGIN.stop}, '*');
				state.callbacks.fire(ELEMENT.ended);
			}
		};
		
		
		this.subscribe = state.callbacks.add;
		this.unsubscribe = state.callbacks.remove;
		
		
		this.status = function() {
			return state.status;
		}
		
		this.play = function() {
			if(state.status == ELEMENT.loading) {
				state.autoplay = true;
			} else if (state.status == ELEMENT.ready) {
				state.play();
			}
		}
		
		this.destroy = function() {
			//
			// Remove the element and free memory
			//
			if(!!state.timer){
				clearTimeout(state.timer);
			}
			if(!!state.status_timer){
				clearTimeout(state.status_timer);
			}
			if(!!state.load_timer){
				clearTimeout(state.load_timer);
			}
			$(window).off('message', state.receive_message);
			
			if(!!state.element) {
				state.element.remove();
				delete state.element;
			}
		}
		
		
		//
		// Initialise the element and set the state
		//
		state.element = $('<iframe frameborder="0"></iframe>').on('load.frame', function(){
			$(this).off('.frame');
			clearTimeout(state.load_timer);
			
			
			//state.other_window = state.element[0].contentWindow; // Causes an exception when domains differ
			state.element[0].contentWindow.postMessage({message:PLUGIN.hello, params: media.file_path, options: options}, '*');	// Let them know who to communicate with
			
			//
			// give it 10 seconds to respond
			//
			state.load_timer = setTimeout(function(){
				delete state.load_timer;
				state.callbacks.fire(ELEMENT.error, ERROR.plugin_stage2_load);
			}, 10000);
			
		}).attr('src', media.plugin.file_path).appendTo(parent);
		
		//
		// give it 10 seconds to load and cancel if it fails
		//
		state.load_timer = setTimeout(function(){
			delete state.load_timer;
			state.element.off('.frame');	// Incase the load occurs after this timer is fired
			state.callbacks.fire(ELEMENT.error, ERROR.plugin_stage1_load);
		}, 10000);
		
		
		
		//
		// on to the elements events
		//
		$(window).on('message', state.receive_message);
		
		
		//
		// Ensure valid data (!media.plugin.can_play_through && !!!timeout)
		//
		if(!media.plugin.can_play_to_end && options.ignore_timeout == false && !!!options.timeout) {
			state.status_timer = setTimeout(function(){
				delete state.status_timer;
				state.callbacks.fire(ELEMENT.error, ERROR.timeout);
			}, 0);	// Instant error
		}
	}
	
	
	function VideoElement(parent, media, options) {	// Timeout optional
		options = $.extend({
			controls: false,			// Prevent pausing
			element: 'video'
		}, options || {});
		
		var state = {
			callbacks: $.Callbacks(),
			status: ELEMENT.loading,
			autoplay: false,
			// element
			// timer
			// stalled_at
			
			play: function(){
				state.status = ELEMENT.playing;
				state.element[0].play();
			},
			check_time: function(){
				if(options.timeout >= state.element[0].currentTime) {
					state.element[0].pause();
					state.status = ELEMENT.ended;
					state.callbacks.fire(ELEMENT.ended);
				}
			},
			check_stalled: function(){
				if(options.controls == false && state.element[0].currentTime == state.stalled_at) {
					state.status = ELEMENT.error;
					state.callbacks.fire(ELEMENT.error, ERROR.video_stalled);
				}
				else
					state.stalled_at = state.element[0].currentTime;
			}
		};
		
		
		this.subscribe = state.callbacks.add;
		this.unsubscribe = state.callbacks.remove;
		
		
		this.status = function() {
			return state.status;
		}
		
		this.play = function() {
			if(!!!options.ignore_play) {
				if(state.status == ELEMENT.loading) {
					state.autoplay = true;
				} else if (state.status == ELEMENT.ready) {
					state.play();
				}
			}
		}
		
		this.destroy = function() {
			//
			// Stop any timers
			//
			if(!!state.timer){
				clearInterval(state.timer);
			}
			
			//
			// Remove the element and free memory
			//
			if(!!state.element) {
				state.element.remove();
				delete state.element;
			}
		}
		
		
		//
		// Initialise the element and set the state
		//
		state.element = $('<' + options.element + ' />').attr('preload', 'auto').on('canplaythrough.ready', function(){
			$(this).off('.ready');
				
			state.status = ELEMENT.ready;
			state.callbacks.fire(state.status);
			
			if(state.autoplay)
				state.play();
			
		}).on('abort.fail error.fail', function(){
			$(this).off('.fail').remove();
			state.status = ELEMENT.error;
			state.callbacks.fire(ELEMENT.error, ERROR.video_load);
			
		}).on('loadeddata.vid', function(){
			state.callbacks.fire(ELEMENT.loaded);
			
		}).on('ended.vid', function(){
			state.status = ELEMENT.ended;
			state.callbacks.fire(ELEMENT.ended);
		}).on('stalled.check', function(){
			state.element.off('.check');
			state.stalled_at = state.element[0].currentTime;
			state.timer = setInterval(state.check_stalled, 5000);
		});
		
		
		//
		// Check for timeout
		//
		if(!!options.timeout)
			state.element.on('timeupdate.vid', state.check_time);
		
		//
		// Check if controls are required
		//
		if(!!options.controls)
			state.element.attr('controls', 'controls');
		else
			state.element.on('pause', function(){
				state.element[0].play();
			});
		
		
		//
		// Add the sources and types
		//
		var format, index, source = false;
		
		for (index in media.formats) {
			format = media.formats[index];
			
			state.element.append($('<source />').attr('src', format.file_path).attr('type', format.accepts_file.mime));
		}
		
		state.element.appendTo(parent);
	}
	
	
	
	
	function ImageElement(parent, media, options) {	// Timeout optional
		options = $.extend({
			ignore_timeout: false					// Allow for previewing
		}, options || {});
		
		var state = {
			callbacks: $.Callbacks(),
			status: ELEMENT.loading,
			// timer
			
			time_up: function(){
				delete state.timer;
				state.status = ELEMENT.ended;
				state.callbacks.fire(ELEMENT.ended);
			}
		};
		
		
		this.subscribe = state.callbacks.add;
		this.unsubscribe = state.callbacks.remove;
		
		
		this.status = function() {
			return state.status;
		}
		
		this.play = function() {
			//
			// Start timers here
			//
			state.status = ELEMENT.playing;
			
			if(options.ignore_timeout == false)
				state.timer = setTimeout(state.time_up, options.timeout);
		}
		
		this.destroy = function() {
			//
			// Stop any timers
			//
			if(!!state.timer){
				clearTimeout(state.timer);
			}
			if(!!state.status_timer){
				clearTimeout(state.status_timer);
			}
			
			//
			// Remove the element and free memory
			//
			if(!!state.element) {
				state.element.remove();
				delete state.element;
			}
		}
		
		//
		// Initialise the element and set the state
		//
		state.element = $('<img />').on('load.img', function(){
			$(this).off('.img')
				.appendTo(parent)
				.scale("stretch", "vert");
				
			state.status = ELEMENT.playing;
			state.callbacks.fire(ELEMENT.ready);
			state.callbacks.fire(ELEMENT.loaded);
		}).on('abort.img error.img', function(){
			$(this).off('.img').remove();
			state.status = ELEMENT.error;
			state.callbacks.fire(ELEMENT.error, ERROR.image_load);
		}).attr('src', media.formats[0].file_path);
		
		
		
		
		//
		// Ensure a timeout is given
		//
		if(options.ignore_timeout == false && !!!options.timeout) {
			state.status_timer = setTimeout(function(){
				delete state.status_timer;
				state.callbacks.fire(ELEMENT.error, ERROR.timeout);
			}, 0);
		}
	}
	
	
	
	//
	// URL Element: state.element = $('<iframe frameborder="0" sandbox="allow-same-origin allow-scripts allow-forms"></iframe>')
	//
	function UriElement(parent, media, options) {	// Timeout optional
		options = $.extend({
			ignore_timeout: false					// Allow for previewing
		}, options || {});
		
		var state = {
			callbacks: $.Callbacks(),
			status: ELEMENT.loading,
			// timer
			// status_timer
			
			time_up: function(){
				delete state.timer;
				state.status = ELEMENT.ended;
				state.callbacks.fire(ELEMENT.ended);
			},
			receive_message: function(event) {
				//
				// Ensure we are chatting to the correct iFrame (can be multiple loaded)
				//
				if(event.originalEvent.source != state.element[0].contentWindow)
					return;
					
				var data = event.originalEvent.data;
					
				//
				// Process the response
				//
				if(data['message'] == ELEMENT.touched) {
					//
					// TODO:: Add a secondary timer
					//	If first timer goes off while this timer is active we ignore
					//	Cancel any existing touched timer and start again
					//	We need to be able to count these too
					//
				}
			}
		};
		
		
		this.subscribe = state.callbacks.add;
		this.unsubscribe = state.callbacks.remove;
		
		
		this.status = function() {
			return state.status;
		}
		
		this.play = function() {
			//
			// Start timers here
			//
			state.status = ELEMENT.playing;
			if(options.ignore_timeout == false)
				state.timer = setTimeout(state.time_up, options.timeout);
		}
		
		this.destroy = function() {
			//
			// Stop any timers
			//
			if(!!state.timer){
				clearTimeout(state.timer);
			}
			if(!!state.status_timer){
				clearTimeout(state.status_timer);
			}
			
			//
			// Remove the element and free memory
			//
			$(window).off('message', state.receive_message);
			if(!!state.element) {
				state.element.remove();
				delete state.element;
			}
		}
		
		//
		// Initialise the element and set the state
		//
		state.element = $('<iframe frameborder="0" sandbox="allow-same-origin allow-scripts allow-forms"></iframe>').on('load.frame', function(){
			$(this).off('.frame');
			state.element[0].contentWindow.postMessage({message:PLUGIN.hello}, '*');		// Let them know who to communicate with
			state.status = ELEMENT.playing;
			state.callbacks.fire(ELEMENT.loaded);
		}).attr('src', media.file_path).appendTo(parent);
		
		//
		// listen for touch events (web page must have been designed for signage)
		//
		$(window).on('message', state.receive_message);
		
		
		
		//
		// Check we are online
		//
		if($.support.connectivity) {
			if(!navigator.onLine) {
				state.status_timer = setTimeout(function(){		// We want to delay the call backs
					delete state.status_timer;
					state.status = ELEMENT.error;
					state.callbacks.fire(ELEMENT.error, ERROR.offline);
				}, 0);
				return;
			}
		}
		
		
		//
		// Ensure a timeout is given
		//
		if(options.ignore_timeout == false && !!!options.timeout) {
			state.status_timer = setTimeout(function(){
				delete state.status_timer;
				state.status = ELEMENT.error;
				state.callbacks.fire(ELEMENT.error, ERROR.timeout);
			}, 0);
		} else {
			state.status_timer = setTimeout(function(){		// We want to delay the call backs
				delete state.status_timer;
				state.status = ELEMENT.playing;
				state.callbacks.fire(ELEMENT.ready);
			}, 0);
		}
	}
	
	
	//
	// Wait for jQuery to load
	//
	$(function() {
		$.extend($.support, {
			connectivity: ('onLine' in window.navigator)
		});
	});
	
	
	//
	// This function makes it happen
	//
	return function(parent, media, options) {
		//
		// Pick the correct element type and load it based on JSON settings for that particular playlist item
		//	Store the element as data attribute of the first child of the parent container
		//
		switch(media.media_type){
			case 0:					// image
				return new ImageElement(parent, media, options);
				break;
			case 1:					// video
				return new VideoElement(parent, media, options);
				break;
			case 2:					// audio
				options = options || {};
				options.element = 'audio';
				return new VideoElement(parent, media, options);
				break;
			case 10:					// Plugin
				return new PluginElement(parent, media, options);
				break;
			case 11:					// url
				return new UriElement(parent, media, options);
				break;
			case 12:					// image_url
				media.formats = [{
					file_path: media.file_path
				}];
				return new ImageElement(parent, media, options);
		}
	};
})(jQuery, this);




