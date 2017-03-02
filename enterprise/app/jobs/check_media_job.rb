class CheckMediaJob < Struct.new(:media_id)
	def perform
		
		media = Media.find(media_id)
		return if media.media_type >= 10
		
		if media.type == :other
			media.converting! if media.can_converting?
			TranscodeOther.check_format(media)
		else
			transcoder = case media.type
				when :image
					TranscodeImage.new(media)
				when :video
					TranscodeVideo.new(media)
				when :audio
					TranscodeAudio.new(media)
			end
			
			transcoder.check_format
			
			if media.formats.where('workflow_state <> ?', 'ready').count() > 0
				media.converting! if media.can_converting?
			end
		end
		
		
	rescue ActiveRecord::RecordNotFound => e
		#
		# Media deleted, ignore and be happy
		#
	rescue InvalidFormat => e
		media = Media.find(media_id)
		media.bad!
		
	rescue Errno::ENOENT => e
		begin
			media.destroy
		rescue
		end
	end
	
	def error(job, exception)
		Airbrake.notify(exception)
	end
end
