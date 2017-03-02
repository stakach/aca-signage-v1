

class PlaylistPublish < Struct.new(:playlist_id)
	def perform
		
		playlist = Playlist.find(playlist_id)
		Playlist.transaction do
			PlaylistMedia.publish(playlist_id)
			playlist.update_displays(true)			# true == this should run
			playlist.published_at = Time.now
			playlist.save!
		end
		
	
	rescue ActiveRecord::RecordNotFound => e
		#
		# Playlist removed, we don't need to worry :)
		#
	end
	
	def error(job, exception)
		Airbrake.notify(exception)
	end
end

