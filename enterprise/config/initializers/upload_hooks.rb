# Be sure to restart your server when you modify this file.
#


Resolute.current_user do
	#
	# This is run in the context of the controller
	#	Return a unique identifier that can be stringified
	#
	[session[:user], session[:group]]
end


#
# Save the newly uploaded file
# 	This will mean less load on the traditional file upload method
#
Resolute.upload_completed  do  |result|
	#
	#	Result is a hash with the following fields
	#		:user	(user identifier defined by current_user above)
	#		:filename (original, unmodified, filename as sent from client side)
	#		:filepath (relational path to the file)
	#		:params (any custom parameters from the client side)
	#		:resumable - the resumable db entry. Will be automatically destroyed on success, not on failure.
	#						This provides you the opportunity to destroy it if you like. Will be nil if it is a regular upload.
	#
	media = Media.new(result[:params].merge({:user_id => result[:user][0]}))
	if media.name == "" || media.name.nil?		# Ensures a name has been set
		media.name = result[:filename]
	end
	media.sanitize_filename(result[:filename])
	
	gm = GroupMedia.new
	gm.group_id = result[:user][1]
	gm.media = media
	
	Media.transaction do
		media.save
		gm.media_id = media.id
		gm.save!
	end
	
	#
	# Move the temp file
	#
	if media.new_record?
		#
		# If the uploaded file is not required delete it and destroy resumable here too
		#
		return media.errors	# Provide the client side with some information
	else
		FileUtils.mv(result[:filepath], media.file_path)
		return true
	end
end


Resolute.check_supported do |file_info|
	if (!AcceptsFile.supports(File.extname(file_info[:filename])).nil?) || (FileConversion.applies(file_info[:filename]).count() > 0)
		return true
	else
		return ['file not supported']
	end
end
