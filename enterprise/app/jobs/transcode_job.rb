require 'streamio-magick'
require 'streamio-ffmpeg'

class TranscodeJob < Struct.new(:item, :format_id, :command, :options)
	def perform
		
		format = Format.includes(:media).find(format_id)
		
		filepath = format.file_path
		
		#
		# Perform conversion here
		#
		if options.nil?
			item.transcode(filepath, command)
		else
			item.transcode(filepath, command, options)
		end
		
		format.reload		# incase media was deleted during the transcoding
		format.complete!
		FileUtils.chmod 0666, format.file_path
	
	rescue ActiveRecord::RecordNotFound => e
		#
		# Media deleted, ignore and be happy
		# Attempt to delete file here if this error occurs
		#
		if filepath.present?
			Delayed::Job.enqueue DeleteFileJob.new(filepath), :queue => 'delete'
		end
	end
	
	def error(job, exception)
		Airbrake.notify(exception)
	end
end
