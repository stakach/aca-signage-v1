class GroupMediaDestroyed < Struct.new(:playlist_ids)
	def perform
		
		playlists = Playlist.find(playlist_ids)
		
		playlists.each do |playlist|
			playlist.update_displays(true)
		end
		
		
	rescue ActiveRecord::RecordNotFound => e
		#
		# Media deleted, ignore and be happy
		#
	end
	
	def error(job, exception)
		Airbrake.notify(exception)
	end
end
