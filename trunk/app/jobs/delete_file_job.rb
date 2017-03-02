class DeleteFileJob < Struct.new(:path)
	
	def perform
		File.delete(path) if File.exists?(path)
	end
	
end
