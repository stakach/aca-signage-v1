require 'streamio-magick'

#
# Checks for image format and performs any conversions or renaming that is required
#
class TranscodeImage
	
	FORMATS = [
		{
			:codec => 'PNG',
			:extension => 'png'
		},
		{
			:codec => 'JPEG'
		},
		{
			:codec => 'GIF'
		}
	]
	
	
	def initialize(media)
		@media = media
	end
	
	
	def check_format
		image = Magick::Image.new(@media.file_path)
		raise InvalidFormat if not image.valid?
		
		@media.width = image.width
		@media.height = image.height
		
		found = false
		format = Format.new
		format.media = @media
		
		FORMATS.each do |type|
			if image.codec =~ /#{type[:codec]}/i
				format.file_path = @media.file_path
				format.accepts_file_id = AcceptsFile.where(:mime => "image/#{type[:codec].downcase}").pluck(:id).first
				found = type
				break
			end
		end
		
		Format.transaction do
			@media.save!
			if found == false
				format.accepts_file_id = AcceptsFile.where(:mime => "image/#{FORMATS[0][:codec].downcase}").pluck(:id).first
				
				conversion = FileConversion.where('target_id IS NULL AND accepts_file_id = ? AND LOWER(applies_to) LIKE ?', format.accepts_file_id, "%#{File.extname(@media.file_path).downcase}%").pluck(:command).first
				conversion = '' if conversion.nil?
				
				#
				# Spawn the conversion task
				#
				format.file_path = @media.file_path[0..-File.extname(@media.file_path).length] + FORMATS[0][:extension]
				if format.file_path == @media.file_path
					format.file_path.insert(-(FORMATS[0][:extension].length + 2), '2')
				end
				
				format.save!
				Delayed::Job.enqueue TranscodeJob.new(image, format.id, conversion, nil), :queue => 'image'
			else
				format.save!
				format.complete!	# workflow state
			end
		end
		
	end
	
end
