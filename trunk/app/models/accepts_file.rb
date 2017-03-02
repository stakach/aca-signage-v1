class AcceptsFile < ActiveRecord::Base

	has_many :file_conversions,	:dependent => :destroy
	
	def first_ext
		ext.split(/\s+/)[0]
	end
	
	def self.supports(extin)
		return AcceptsFile.where('LOWER(ext) LIKE ? AND enabled = ?', "%#{extin.downcase}%", true).first
	end
	
	protected
	
	validates_presence_of :ext, :mime
	
end
