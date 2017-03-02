class MediaUpdated < Struct.new(:media_id)
	def perform
		
		media = Media.find(media_id)
		
		media.playlists.uniq.each do |playlist|
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
