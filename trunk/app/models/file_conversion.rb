class FileConversion < ActiveRecord::Base

	belongs_to :accepts_file
	
	before_create	:set_order
	
	def self.search(search_terms = nil)
		result = FileConversion.joins(:accepts_file).includes(:accepts_file).order('file_conversions.ordinal ASC')
		
		if(!search_terms.nil? && search_terms != "")
			search = '%' + search_terms.chomp.gsub(' ', '%').downcase + '%'
			result = result.where('LOWER(file_conversions.description) LIKE ? OR LOWER(accepts_files.mime) LIKE ? OR LOWER(file_conversions.applies_to) LIKE ?', search, search, search)
		end
		
		return result
	end
	
	scope :applies, lambda {|path|
		includes(:accepts_file).order('file_conversions.ordinal ASC').where('file_conversions.enabled = ?', true).where('LOWER(file_conversions.applies_to) LIKE ?', "%#{File.extname(path).downcase}%")
	}
	
	
	def do_command(path)
		newname = FileConversion.getName(path, accepts_file.first_ext)
		run = command.gsub("%ifile%", path)
		run.gsub!("%ofile%", File.join(newname[0], newname[1]))
		
		run.split('&').each do |subcommand|
			system(subcommand.strip)
		end
	end
	
	
	#def clean_up(path)
	#	FileUtils.remove_file(path, true)	# remove old file
	#	ret = FileConversion.getName(path, accepts_file.first_ext)
	#	ret << accepts_file.mime
	#end
	
	#
	# Same as Playlist_medias
	#
	def self.order_all(ids)
		#
		# by using the sql case statement we only hit the database once
		#	Scales better.
		#
		sql = "UPDATE file_conversions SET updated_at = '#{Time.now.utc.to_s(:db)}', ordinal = CASE id "
		ids.each_with_index do |id, index|
			sql += "WHEN #{id} THEN #{index} "
		end
		sql += "END WHERE id IN (#{ids.join(',')})"
		connection.execute(sql)
		
		#
		# N DB requests is slow (only use if not supported in DB)
		#
		#PlaylistMedia.transaction do
		#	ids.each_with_index do |id, index|
		#		item = PlaylistMedia.update(id, :ordinal => index)
		#	end
		#end
	end
	
	
	protected
	
	
	def set_order		# On create
		self[:ordinal] = FileConversion.maximum(:ordinal)
		if self[:ordinal].class != Fixnum
			self[:ordinal] = -1
		end
		self[:ordinal] = self[:ordinal] + 1
	end
	
	
	def self.getName(path, ext)
		newname = File.split(path)	#change extention
		newname[1].reverse!
		newname[1].sub!(File.extname(path).reverse, ext.reverse)
		newname[1].reverse!
		newname
	end
	
	validates_presence_of :applies_to, :description

end
