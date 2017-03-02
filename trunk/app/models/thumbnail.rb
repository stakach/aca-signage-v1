class Thumbnail < ActiveRecord::Base
	belongs_to :media
	
	after_destroy	:delete_file
	
	
	protected
	
	
	def delete_file
		File.delete(self.file_path)
	end
end
