/**
*	ACA Signage Core Media Downloader
*	Downloads media in the background (where possible) - whilst managing playlists and schedules for the players
*	
*   Copyright (c) 2012 Advanced Control and Acoustics.
*	
*	@author 	Stephen von Takach <steve@advancedcontrol.com.au>
* 	@copyright  2012 advancedcontrol.com.au
**/


var Downloader = (function(global) {
	
	
	return function(callback) {
		this.controller = function(data) {
			//
			// This is the incoming message handler
			//
			switch(data.message){
				case SIG.update:
					display_update(data.settings);
					break;
				case SIG.supports:
					support = data.support;
					break;
			}
		};
		
		
		var playlists = {},			// playlist_id => The play list lookup
			medias = {},			// media_id => media schema
			groups = {},			// group_id => default play lists + scheduled lists
			scheduleTimer = null,
			nextSchedules = [],		// Coming up in order
			currentSchedules = [],	// Ending in order
			previousRegular = [],	// Currently playing regular play lists
			support;				// Features supported by this browser
			
			
		function display_update(newlists) {
			var list, index, listIndex, found, defaultTime,
				newItems = {}, theTime = new Date().getTime();
				
			if (scheduleTimer != null) {
				clearTimeout(scheduleTimer);
				scheduleTimer = null;
			}
			
			//
			// Sort and index the playlists
			//
			playlists = {};
			for (listIndex in newlists.live_playlists) {									// Run through the playlists
				list = newlists.live_playlists[listIndex].published_medias;					// Shortcut to the media list
				defaultTime = newlists.live_playlists[listIndex].default_timeout * 1000;	//default timeout assignment
				
				if(newlists.live_playlists[listIndex].random == false)				// Check if it requires sorting
					list.sort(playlistSort);
					
				playlists[newlists.live_playlists[listIndex].id] = newlists.live_playlists[listIndex];	// Index by playlist id
					
				//
				// Index the media
				//
				for (index in list) {												// Run through the media items
					if(newItems[list[index].media.id] == undefined) {				// Check the media item hasn't already been indexed
						if(list[index].media.media_type < 10)						// Non link based media never changes (look up in existing cache)
							newItems[list[index].media.id] = medias[list[index].media.id] || processMedia(list[index].media);
						else
							newItems[list[index].media.id] = list[index].media;
					}
					
					if(newItems[list[index].media.id] != false) {
						if (!!!list[index].pub_run_time) {					// Work out the timeout for the item (if nothing defined)
							if(list[index].media.media_type == 0 || list[index].media.media_type > 10)
								list[index].pub_run_time = defaultTime;
							else if(list[index].media.media_type == 10 && !list[index].media.plugin.can_play_to_end)
								list[index].pub_run_time = defaultTime;
						} else if(list[index].pub_run_time != undefined) {
							list[index].pub_run_time = list[index].pub_run_time * 1000;
						}
						
						list[index].media = list[index].media.id;					// Normalised
							
						if (list[index].pub_start_time != undefined)
							list[index].pub_start_time = list[index].pub_start_time * 1000;
					}
					else
						delete list[index];
				}
			}
			medias = newItems;		// Replace the media list with the new media list
			
			
			//
			// Build the currently playing list and sort the schedules
			//
			newItems = {};
			currentSchedules = [];
			nextSchedules = [];
			
			
			for (index in newlists.display_groups) {
				newItems[newlists.display_groups[index].id] = newlists.display_groups[index];	// Index the display group
			}
			
			
			for (index in newlists.live_schedules) {	// Run through all the schedules
				
				list = newlists.live_schedules[index];
				listIndex = list.schedule;
				
				list["group_id"] = listIndex.display_group_id;						// Add the group id to the schedule
				list["created_at"] = Date.parse(listIndex.created_at);				// Convert the dates to integers
				list.do_end = Date.parse(list.do_end);
				list.do_start = Date.parse(list.do_start);
				
				
				if (listIndex.emergency) {			// Give exclusiveness a rating
					listIndex.exclusive = true;
					listIndex.emergency = 5
				} else if (listIndex.exclusive) {
					listIndex.emergency = 1;
				}
				
				list["exclusive"] = listIndex.exclusive;
				list["emergency"] = listIndex.emergency;
				list["playlist_id"] = listIndex.playlist_id;
				
				listIndex = null;		// Unreferenced
				delete list.schedule;	// Deleted
				
				
				//
				// Add the schedules to their appropriate arrays
				//
				if(list.do_start < theTime && list.do_end > theTime)
					currentSchedules.push(list);
				else if(list.do_start > theTime)
					nextSchedules.push(list);		// These should all have the same start time
			}
			groups = newItems;	// Update the groups list
			nextSchedules.sort(scheduleStartSort);
			
			//
			// Generate the currently playing list
			//
			updateCurrentlyPlaying();
		}
		
		
		
		function updateCurrentlyPlaying() {
			var index, item, group_clone = {}, exclusive = null, current = [];
			
			//
			// Clone the groups list
			// 
			for (index in groups) {
				if(!!groups[index].playlist_id)				// We only to clone groups that have default play lists
					group_clone[index] = groups[index].playlist_id;
			}
			
			//
			// Run through the currentSchedule and remove the groups that are present in that list
			//
			currentSchedules.sort(scheduleCreatedSort);		// As we want the schedules to play in order they were created
			for (index in currentSchedules) {
				item = currentSchedules[index];
				
				delete group_clone[item.group_id];
				
				if(item.exclusive) {	// Check for an exclusive schedules
					if(exclusive == null)
						exclusive = item;
					else if (exclusive.emergency < item.emergency)
						exclusive = item;
					else if (exclusive.emergency == item.emergency && exclusive.created_at > item.created_at)
						exclusive = item;
				} else {
					current.push(item.playlist_id);
				}
			}
			
			//
			// build the current playing list
			//
			if(exclusive == null) {
				for (index in group_clone) {
					current.push(group_clone[index]);		// Add any default play lists
				}
			} else {
				current = [exclusive.playlist_id]
			}
			
			//
			// build combined play list
			//
			buildPlaylist(current, exclusive);
			
			
			//
			// Start the schedule timer
			//
			currentSchedules.sort(scheduleEndSort);		// Re-order the current schedules so we have easy access to the first to end
			setScheduleTimer();
		}
		
		
		
		function buildPlaylist(current, exclusive) {
			var index, random = [], regular = [], combined = [], restart = false;
			
			//
			// Sort random from regular playlists
			//
			for (index in current) {
				if(playlists[current[index]].random)
					random.push(playlists[current[index]]);
				else
					regular.push(playlists[current[index]]);
			}
			
			
			//
			// Determine if the non-random play lists have changed
			//	We only check regular as random lists may be dynamically injected (advertising etc)
			//
			for (index in regular) {		// The case where we go from one or more play lists to none is handled implicitly
				if(previousRegular[index] == undefined) {
					break;					// Don't restart if we are adding new content and the existing is the same up to this point
				} else if(regular[index] != previousRegular[index]) {
					restart = true;
					break;
				}
			}
			previousRegular = regular;
			
			
			//
			// combine the random play lists
			//
			for (index in random) {
				combined.push.apply(combined, random[index].published_medias);
			}
			
			
			//
			// Check if there are random lists
			//
			if(combined.length > 0)	{
				random = combined;
				random.sort(randSort);	// Randomise them a bit more
				combined = [];			// We'll start the combining again
				
				//
				// Insert ordered content, two cases here.
				//
				if(regular.length >= random.length){	// If there are more regular PLAYLISTS then random MEDIA items
					//
					// We need to intermingle the random content throughout the regular content
					//
					var mediaIndex = 0;
					for (index in regular) {
						combined.push(random[mediaIndex]);
						combined.push.apply(combined, regular[index].published_medias);
						
						mediaIndex += 1;
						if (mediaIndex >= random.length)
							mediaIndex = 0;
					}
				} else if (regular.length > 0) {
					//
					// We can easily insert regular lists in between random lists
					//
					var len = Math.ceil(random.length / regular.length),
						end = Math.ceil(random.length / regular.length),
						start = 0;
					
					for (index in regular) {
						combined.push.apply(combined, random.slice(start, end));
						combined.push.apply(combined, regular[index].published_medias);
						
						start += len;
						end += len;
					}
				  } else {
					combined = random;
				  }
			} else {	// No random items
				for (index in regular) {
					combined.push.apply(combined, regular[index].published_medias);
				}
			}
			
			
			if (!!exclusive)
				exclusive = exclusive.emergency;
			else
				exclusive = 0;
			
			//
			//	TODO:: Send the media references and the combined list to the player with the emergency level!!!
			//
			callback({
				message: SIG.new_list,
				exclusive: exclusive,
				playlist: combined,
				media: medias,
				restart: restart			// Should this update restart the player from the top of the list?
			});
		}
		
		
		
		//
		// Sorting functions
		//
		function randSort() {
			return (Math.round(Math.random()) - 0.5);
		}
		
		function playlistSort(a, b) {
			return a.pub_ordinal - b.pub_ordinal;
		}
		
		function scheduleEndSort(a, b) {
			return a.do_end - b.do_end;
		}
		
		function scheduleStartSort(a, b) {
			return a.do_start - b.do_start;
		}
		
		function scheduleCreatedSort(a, b) {
			return a.created_at - b.created_at;
		}
		
		
		//
		// Remove any formats that can't be played
		//	if space is allocated, add to the down load queue
		//	return the media item
		//
		function processMedia(media){
			var index, type, accepts = [];
			
			if(!!support[MEDIA_TYPES[media.media_type]]) {	// if the media type is supported
				for(index in media.formats) {
					type = media.formats[index].accepts_file.mime.split('/');
					if(type.length > 1) {
						if(!!support.mediaTypes[type[1]]) {
							media.formats[index].file_path = media.formats[index].file_path.split('public')[1];
							accepts.push(media.formats[index]);
						}
					}
				}
				
				if(accepts.length > 0) {
					media.formats = accepts;
					//
					// TODO:: add to the down load queue here if space allocated
					//
					media.background = '#' + media.background;
					return media;
				}
			}
			
			//
			// TODO:: decide here if media item should be checked periodically as it may be converting
			//	If so add it to a check list however still return false at this point.
			//
			
			return false;
		}
		
		
		//
		// This is called by the timer
		//
		function updateSchedules() {
			//
			// Run through the schedules
			//	If anything has changed then find currently playing
			//
			var theTime = new Date().getTime();
			if((nextSchedules.length > 0 && theTime > nextSchedules[0].do_start) || (currentSchedules.length > 0 && theTime > currentSchedules[0].do_end)) {
				var index, next = [], curr = [];
				
				for(index in nextSchedules){
					if (nextSchedules[index].do_start < theTime && nextSchedules[index].do_end > theTime)
						curr.push(nextSchedules[index]);
					else if (nextSchedules[index].do_start > theTime)
						next.push(nextSchedules[index]);
				}
				
				for(index in currentSchedules){
					if (currentSchedules[index].do_end > theTime)
						curr.push(currentSchedules[index]);
				}
				
				currentSchedules = curr;
				nextSchedules = next;
				
				//currentSchedules.sort(scheduleEndSort); // This is sorted in currently playing
				nextSchedules.sort(scheduleStartSort);
				updateCurrentlyPlaying();
				
			} else {
				//
				// Reschedule the timer
				//
				setScheduleTimer();
			}
		}
		
		function setScheduleTimer() {
			var theTime = new Date().getTime();
			
			if(nextSchedules.length > 0) {
				var difference1, difference2 = 60000;
				
				difference1 = nextSchedules[0].do_start - theTime;
				if(currentSchedules.length > 0)
					difference2 = currentSchedules[0].do_end - theTime;
					
				if(difference1 > 60000)
					difference1 = 60000;
					
				if(difference2 > 60000)
					difference2 = 60000;
					
				if(difference1 > difference2)
					difference1 = difference2;
					
				if(difference1 < 60000) {
					if(difference1 < 0)
						updateSchedules();
					else
						scheduleTimer = setTimeout(updateSchedules, difference1);
				} else {
					scheduleTimer = setTimeout(updateSchedules, 60000);
				}
				
			} else if(currentSchedules.length > 0) {
				var difference1 = currentSchedules[0].do_end - theTime;
				
				if(difference1 > 60000)
					difference1 = 60000;
				
				if(difference1 < 60000) {
					if(difference1 < 0)
						updateSchedules();
					else
						scheduleTimer = setTimeout(updateSchedules, difference1);
				} else {
					scheduleTimer = setTimeout(updateSchedules, 60000);
				}
			}
		}
		
	};	
	
})(this);

