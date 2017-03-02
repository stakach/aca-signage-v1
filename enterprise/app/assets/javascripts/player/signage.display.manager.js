

var DisplayManager = (function($, global) {
	
	return function(videoDownloader, videoPlayer, audioDownloader, audioPlayer, callback) {
		var self = this,
			appCache,
			$appCache,
			appCacheFirstCheck = true,				// If screen offline for months may be seriously out of date
			cacheTimer,
			settings,
			api,
			geoStart,
			geoTimer,
			geoLocation,
			restartLookup = {
				video: videoPlayer,
				display: self
				//audio: audioPlayer	TODO:: when there is an audio player
			},
			waitingRestart = {},
			doRestart = {},
			restarting = false,
			index;
		
		function bindCache() {
			//
			// Unbind appCache if defined
			//
			if(appCache != undefined) {
				$appCache.off('.event');
				appCache.swapCache();
				
				if(appCacheFirstCheck)				// We have no idea how out of date we could be!!
					window.location.reload();
				else
					setTimeout(getSettings, 0);		// Get settings next time through the reactor
			}
			
			//
			// Assign the new cache
			//
			appCache = window.applicationCache;
			$appCache = $(appCache);
			
			//
			// Bind events
			//
			$appCache.on('updateready.event', bindCache)
				.on('noupdate.event', function(){
					appCacheFirstCheck = false;
					//
					// TODO:: reload is a possibility
					//
				});
		}
		
		function getSettings(){
			$.ajax({
				url: window.location.pathname.split('.')[0] + '.json',
				dataType: 'json',
				success: function(data, textStatus, jqXHR){
					if(settings == undefined || settings.last_updated != data.last_updated) {
						settings = data;
						applySettings();
					}
				},
				error: function(jqXHR, textStatus, errorThrown){
					setTimeout(getSettings, 10000);					// Lets retry this in 10 seconds time
				}
			});
		}
		
		function getLocation() {
			navigator.geolocation.getCurrentPosition(
		 		function (position) {
					if(navigator.onLine && (position.coords.latitude != geoLocation.coords.latitude || position.coords.longitude != geoLocation.coords.longitude)) {
						//
						// TODO:: requires backend support
						//	(.key, location, rails-ujs, etc)
						//
						$.ajax({
							url: '/displays/' + settings.id + '/location',
							data: position.coords,
							type: 'POST'
						});
					}
					
					geoLocation = position;
				},
				function (error) {},
				{
					enableHighAccuracy: true
				}
			);
		}
		
		function startGeoLocating() {
			$.ajax({
				url: window.location.pathname.split('.')[0] + '.key',
				success: function(data, textStatus, jqXHR){
					//
					// Apply the csrf key here so we can post requests with the current session
					//
					$('meta[name="csrf-token"]').attr('content', data);
					if(!!settings.geolocate)
						geoTimer = setInterval(getLocation, 10000);
						
					geoStart = undefined;
				},
				error: function(jqXHR, textStatus, errorThrown){
					geoStart = setTimeout(startGeoLocating, 10000);					// Lets retry this in 10 seconds time
				}
			});
		}
		
		function applySettings(){
			if(api == undefined)
				api = settings.api;
				
			if (api != settings.api)		// TODO:: reload gracefully
				window.location.reload();
			
			
			if(!!settings.physical) {
				//
				// Check for first time run
				//
				if($.support.cache && appCache == undefined) {
					switch(window.applicationCache.status) {
						case 5:		// OBSOLETE (we need to refresh)
							window.location.reload();
							break;
						case 4:		// UPDATE READY
							window.applicationCache.swapCache();
							window.location.reload();
							break;
					}
					
					bindCache();
					try {
						appCache.update();
					} catch(e){}
				}
				
				
				//
				// Ensure geo-location is running or disabled if settings.geolocate
				//
				if(geoTimer != undefined)
					clearInterval(geoTimer);
				else if (geoStart != undefined)
					clearTimeout(geoStart)
				
				if(!!settings.geolocate && support.geoloc)
					startGeoLocating();
				else {
					geoTimer = undefined;
					geoStart = undefined;
				}
				
				//
				// Ensure storage is allocated if settings.max_space > 0	(the screen shouldn't ask twice)
				//
				if (settings.max_space > 0 && support.fs) {
					//
					// Get the currently allocated space
					//
					window.storageInfo = window.storageInfo || window.webkitStorageInfo;
					window.storageInfo.queryUsageAndQuota(webkitStorageInfo.PERSISTENT, function(usage, quota){
						if(settings.max_space > quota) {
							window.storageInfo.requestQuota(PERSISTENT, spaceRequired, function spaceGranted(space) {
								spaceAllocated = space;
								//
								// TODO:: Inform the downloadrs of their space allocation
								// http://net.tutsplus.com/tutorials/html-css-techniques/toying-with-the-html5-filesystem-api/
								// http://www.html5rocks.com/en/tutorials/file/filesystem/
								//
							}, function(e) {
								//
								// An error occured.
								//	Downloaders won't use offline storage and rely on the cache instead
								//
							});
						}
					});
					
				}
				
			}
			
			videoPlayer.displayMessage({		// This is first in case video down loader is not on another thread
				message: SIG.supports,
				settings: {forward_back: !!settings.forward_back}
			});
			
			videoDownloader.postMessage({
				message: SIG.update,
				settings: settings
			});
		}
		
		
		
		//
		// Generic restart signal code
		//
		for (index in restartLookup) {
			waitingRestart[index] = true;
			doRestart[index] = false;
		}
		
		
		setTimeout(function(){		// Don't restart any more then once every 2min
			self.canRestart('display');
		}, 120000);
		this.displayMessage = function(){};
		doRestart.display = true;	// We will be ready once waiting is cleared
		
		
		this.canRestart = function(player){			
			waitingRestart[player] = false;
			
			for (index in waitingRestart) {
				if(waitingRestart[index])
					return false;
			}
			
			//
			// Inform video of restart
			//
			if(!restarting) {
				clearInterval(cacheTimer);				// Stop looking for updates
				
				setTimeout(function(){
					
					for (index in restartLookup) {
						restartLookup[index].displayMessage({
							message: SIG.restart
						});
					}
					
				}, 0);			// Inform of restart
				
				restarting = true;
			}
			
			return true;	// Audio ignores this, video will pre-emptively stop playing
		};
		
		
		this.readyRestart = function(player){
			doRestart[player] = true;
			
			for (index in doRestart) {
				if(!doRestart[index])
					return;
			}
			
			window.location.reload();			// Everything is ready to restart!
		};
		
		
		
		
		videoPlayer.displayMessage({
			message: SIG.hello,
			from: this
		});
		
		
		//
		// Start the player
		//
		getSettings();
		cacheTimer = setInterval(function() {
			if(appCache != undefined) {
				try {
					appCache.update();
				} catch (e) {
					//
					// TODO:: inform of error
					//
					getSettings();
				}
			} else {
				getSettings();
			}
		}, 60000);	// Every min
	};
	
})(jQuery, this);

