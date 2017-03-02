class TranscodeAudio
	
	FORMATS = [
		{
			:mime => 'audio/mp4',
			:acodec => 'aac',
			:extension => ['m4a', 'aac']
		},
		{
			:mime => 'audio/vorbis',
			:acodec => 'vorbis',
			:extension => ['ogg', 'oga']
		}
	]
	
	
	def initialize(media)
		@media = media
	end
	
	
	def check_format
		movie = FFMPEG::Movie.new(@media.file_path)
		raise InvalidFormat if not movie.valid?
		
		#
		# Check for video stream - if exists then we send to video
		#
		if movie.video_codec.present?
			@media.media_type = 1
			@media.save!
			Delayed::Job.enqueue CheckMediaJob.new(@media.id), :queue => 'checking'
			return
		end
		
		@media.runtime = movie.duration
		@media.save!
		
		FORMATS.each do |type|
			format = Format.new
			format.media = @media
			format.accepts_file_id = AcceptsFile.where(:mime => type[:mime]).pluck(:id).first
			
			a_match = !!(movie.audio_codec =~ /#{type[:acodec]}/i)
			
			if !a_match || !type[:extension].include?(File.extname(@media.file_path).downcase[1..-1])
				conversion = FileConversion.where('target_id IS NULL AND accepts_file_id = ? AND LOWER(applies_to) LIKE ?', format.accepts_file_id, "%#{File.extname(@media.file_path).downcase}%").pluck(:command).first
				conversion = '' if conversion.nil?
				
				if a_match
					conversion = '-acodec copy'
				end
				
				#
				# Spawn the conversion task
				#
				format.file_path = @media.file_path[0..-File.extname(@media.file_path).length] + type[:extension][0]
				if format.file_path == @media.file_path
					format.file_path.insert(-(type[:extension][0].length + 2), '2')
				end
				format.save!
				
				Delayed::Job.enqueue TranscodeJob.new(movie, format.id, conversion, {}), :queue => 'audio'
			else
				#
				# Save format entry as is
				#
				format.file_path = @media.file_path
				format.save!
				format.complete!	# workflow state
			end
		end
	end
	
end
