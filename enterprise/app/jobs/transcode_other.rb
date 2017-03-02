#
# If command is a valid URI then we offload to a conversion server
# If command is not a URI we execute locally
#

class TranscodeOther < Struct.new(:media_id, :command, :output)
	
	
	def perform	
		result = system(command)
		media = Media.find(media_id)
		
		if result == true && File.size?(output) != nil	# returns nil if file does not exist or is 0 bytes
			begin
				File.delete(media.file_path)
			rescue
			end
			media.file_path = output
			media.media_type = nil
			media.save!		# Save should recheck the media_type
			media.recheck!
			Delayed::Job.enqueue CheckMediaJob.new(media.id), :queue => 'checking'
		else
			begin
				File.delete(output)
			rescue
			end
			media.failure!
		end
	
	rescue ActiveRecord::RecordNotFound => e
		#
		# Media deleted, ignore and be happy
		#
	end
	
	def error(job, exception)
		Airbrake.notify(exception)
	end
	
	
	
	def self.check_format(media)
		conversion = JSON.parse(FileConversion.applies(media.file_path).pluck(:command).first)
		file = media.file_path[0..-(File.extname(media.file_path).length + 1)]	# File without the ext
		
		if conversion.is_a?(Hash)
			#
			# TODO:: This is where the offload logic will go
			# => Powerpoint on a windows server, apple formats to an apple server
			#
			# {:server_url => '', :port => '', :tls => false}
			#
			#
		else
			#
			# Get the command to be run and the output
			#
			output = conversion[0].gsub('#{output}', file)
			command = conversion[1].gsub('#{input}', media.file_path).gsub('#{output}', file)
			
			#
			# Run as a video conversion
			#
			Delayed::Job.enqueue TranscodeOther.new(media.id, command, output), :queue => 'video'
		end
	end
	
	
	def self.build_target(media_id, target_id)
		media = Media.find(media_id)
		conversions = FileConversion.include(:accepts_file).where('target_id = ?', target_id)
		conversions.each do |conversion|
			#
			# Create format entry
			#
			format = Format.new
			format.media = media
			format.accepts_file = conversion.accepts_file
			format.target_id = target_id
			
			ext = conversion.accepts_file.ext.split(' ')[0]
			format.file_path = media.file_path[0..-(File.extname(media.file_path).length + 1)] + ext
			if format.file_path == media.file_path
				format.file_path.insert(-(ext.length + 1), conversion.id.to_s)
			end
			format.save!
			
			
			#
			# Define the options (build targets have defined widths and heights)
			#
			queue = nil
			transcoder = nil
			options = nil
			transcoder_options = nil
			
			if conversion.accepts_file.mime =~ /audio/
				queue = 'audio'
				options = conversion.command
				transcoder = FFMPEG::Movie.new(media.file_path)
			else
				if conversion.accepts_file.mime =~ /video/
					options = {
						:resolution => "#{conversion.width}x#{conversion.height}",
						:custom => conversion.command
					}
					
					if conversion.height > conversion.width
						transcoder_options = {:preserve_aspect_ratio => :height}
					else
						transcoder_options = {:preserve_aspect_ratio => :width}
					end
					
					queue = 'video'
					transcoder = FFMPEG::Movie.new(media.file_path)
				else
					options = "-resize #{conversion.width}x#{conversion.height}"
					options += " #{conversion.command}" if conversion.command.present?
					
					queue = 'image'
					transcoder = Magick::Image.new(media.file_path)
				end
			end
			
			#
			# Build conversion target here (spawning a new job)
			#
			Delayed::Job.enqueue TranscodeJob.new(transcoder, format.id, options, transcoder_options), :queue => queue
		end
	end
	
end
