require 'streamio-ffmpeg'

#
# Checks for video format
# 	* Copies files to correct container if possible
# 	* Spawns multiple transcoders for conversion
#
# => conversion.command == JSON: ["video params", "audio params"]
#

class TranscodeVideo
	
	FORMATS = [
		{
			:vcodec => 'h264',
			:acodec => 'aac',
			:extension => 'mp4'
		},
		{
			:vcodec => 'vp8',
			:acodec => 'vorbis',
			:extension => 'webm'
		}
	]
	
	
	def initialize(media)
		@media = media
	end
	
	
	def check_format
		movie = FFMPEG::Movie.new(@media.file_path)
		raise InvalidFormat if not movie.valid?
		
		#
		# Check for video stream - if none then we send to audio
		#
		if movie.video_codec.nil?
			@media.media_type = 2
			@media.save!
			Delayed::Job.enqueue CheckMediaJob.new(@media.id), :queue => 'checking'
			return
		end
		
		@media.runtime = movie.duration
		@media.width = movie.width
		@media.height = movie.height
		@media.save!
		
		FORMATS.each do |type|
			format = Format.new
			format.media = @media
			format.accepts_file_id = AcceptsFile.where(:mime => "video/#{type[:extension]}").pluck(:id).first
			
			#
			# Check if the codecs are correct
			#
			v_match = !!(movie.video_codec =~ /#{type[:vcodec]}/i)
			a_match = !!(movie.audio_codec =~ /#{type[:acodec]}/i)
			
			if !v_match || !a_match || type[:extension] != File.extname(@media.file_path).downcase[1..-1]
				conversion = JSON.parse(FileConversion.where('target_id IS NULL AND accepts_file_id = ? AND LOWER(applies_to) LIKE ?', format.accepts_file_id, "%#{File.extname(@media.file_path).downcase}%").pluck(:command).first)
				custom = nil
				
				#
				# Build conversions
				# 	Copy matching codecs
				#
				if v_match
					custom = '-vcodec copy'
				else
					custom = conversion[0]
				end
				
				if a_match
					custom += ' -acodec copy'
				elsif movie.audio_codec.present?	# Ensure there is an audio stream
					custom += " #{conversion[1]}"	# Adding a space here
				end
				
				#
				# Spawn the conversion task
				#
				format.file_path = @media.file_path[0..-File.extname(@media.file_path).length] + type[:extension]
				if format.file_path == @media.file_path
					format.file_path.insert(-(type[:extension].length + 2), '2')
				end
				format.save!
				
				Delayed::Job.enqueue TranscodeJob.new(movie, format.id, custom, {}), :queue => 'video'
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
