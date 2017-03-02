
var SIG = {
		shutdown: 0,	// Exit the web worker gracefully if possible
		update: 1,		// Display -> down loader: Settings + play list update
		new_list: 2,	// Down loader -> player : a new play list is available
		supports: 3,	// Player -> down loader: file formats supported
		hello: 4,		// display -> player: Informs player of display
		restart: 5		// Used in various locations
	},
	
	ERROR = {
		format: 0,			// Format not available
		plugin: 1,			// Plug in gave an error response
		timeout: 2,			// No timeout was provided when needed
		video_stalled: 3,	// The video has stalled unexpectedly
		video_load: 4,		// A video failed to load
		image_load: 5,		// An image failed to load
		plugin_stage1_load: 6,		// A plugin failed to load the at the signage end
		plugin_stage2_load: 7,		// The plugin failed to respond
		offline: 8
	},
	
	PLUGIN = {
		hello: 0,		// Passes the parent object to a plug in
		play: 1,		// Tells the plug in to play
		stop: 2		// Tells the plug in to stop playing
	},
	
	ELEMENT = {
		ready: 0,		// We are ready to play the current element
		loaded: 1,		// We can start down-loading the next element
		ended: 2,		// The element play back has finished or timer expired
		error: 3,		// There was an error with the current element
		fallback: 4,	// A plug in had to use a browser plug in (like flash) to play
		touched: 5,		// An element was interacted with
		loading: 6,		// The element is currently loading
		playing: 7		// The element is currently playing
	},
	
	
	//
	// Same as defined in playlist_medias.rb
	//
	EFFECTS = ['fade to black', 'cut instantly to item', 'cross fade', 'explode', 
				'push in from the top', 'push in from the bottom', 'push in from the left', 'push in from the right',
				'slide out from the top', 'slide in from the top', 'slide out from the bottom', 'slide in from the bottom',
				'slide out from the left', 'slide in from the left', 'slide out from the right', 'slide in from the right',
				'spin out', 'spin in', 'fly out', 'fly in', 'iris',
				'flip horizontally', 'flip vertically'];
	
	//
	// Same as defined in media.rb
	//
	MEDIA_TYPES = {
		other: -1,
		image: 0,
		video: 1,
		audio: 2,
		plugin: 10,
		url: 11,
		image_url: 12,
		"-1": "other",
		"0": "image",
		"1": "video",
		"2": "audio",
		"10": "plugin",
		"11": "url",
		"12": "image_url"
	};
	