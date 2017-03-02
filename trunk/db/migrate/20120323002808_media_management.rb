class MediaManagement < ActiveRecord::Migration
	def up
		
		rename_column 	:resolute_resumables, :paramters, :custom_params
		
		create_table :plugins do |t|
			t.references	:group	# for localised plugin support
			t.string	:name,		:allow_null => false
			t.text		:file_path,	:allow_null => false
			t.text		:help
			t.text		:validation
			t.boolean	:can_play_to_end,	:allow_null => false, :default => false
			t.boolean	:requires_data,		:allow_null => false, :default => true
		end
		
		create_table :targets do |t|
			t.string	:identifier,	:allow_null => false
			t.text		:notes
		end
		
		#
		# Desired width and height of media for a particular target
		#
		add_column		:file_conversions, :target_id, :integer
		add_column		:file_conversions, :width, :integer
		add_column		:file_conversions, :height, :integer
		
		
		create_table :formats do |t|
			t.references :media,		:allow_null => false
			t.references :accepts_file,	:allow_null => false
			t.references :target
			
			t.text		:file_path
			t.string	:workflow_state
		end
		
		#
		# Move all the media references to the new structure
		#
		Format.reset_column_information
		Media.find_each do |media|
		#	if media.workflow_state == 'ready'
		#		format = Format.new
		#		format.media_id = media.id
		#		format.accepts_file_id = AcceptsFile.where(:mime => media.content_type).pluck(:id).first
		#		format.file_path = media.path
		#		format.workflow_state = 'ready'
		#		format.save
		#		
		#		if media.alt_path.present?
		#			format = Format.new
		#			format.media_id = media.id
		#			format.accepts_file_id = AcceptsFile.where(:mime => media.alt_type).pluck(:id).first
		#			format.file_path = media.alt_path
		#			format.workflow_state = 'ready'
		#			format.save
		#		end
		#	end
			#
			# TODO:: Map media types here
			#	We need to check the content type and map it to media_type (as defined in the new version)
			#
			Delayed::Job.enqueue DeleteFileJob.new(media.alt_path), :queue => 'delete'
		end
		
		remove_column	:medias, :content_type
		remove_column	:medias, :alt_path
		remove_column	:medias, :alt_type
		rename_column 	:medias, :path, :file_path
		add_column		:medias, :width, :integer
		add_column		:medias, :height, :integer
		add_column		:medias, :runtime, :integer
		add_column		:medias, :plugin_id, :integer
		add_column		:medias, :background, :string,	:allow_null => false, :default => '000', :limit => 6
		add_column		:medias, :caption_id, :integer	# This is a seperate table (can be created through media)
		
		#
		# Captioning support
		#
		create_table :captions do |t|
			t.string	:title
			t.string	:caption
			t.integer	:timeout,	:allow_null => false,	:default => 5
			t.integer	:font_size,	:allow_null => false,	:default => 40
			t.string	:font_family # this should include weight, style etc
		end
		
		
		#
		# Playlist updates
		#
		add_column	:playlists, :random, :boolean,	:allow_null => false, :default => false
		add_column	:playlists, :preload, :integer,	:allow_null => false, :default => 0		# count of reasons for pre-loading
		add_column	:playlists, :default_transition,	:integer,	:allow_null => false, :default => 0
		
		
		Media.reset_column_information
		Media.find_each do |media|
			media.workflow_state = 'checking'
			media.save
			Delayed::Job.enqueue CheckMediaJob.new(media.id), :queue => 'checking'
		end
		
		create_table :thumbnails do |t|
			t.references :media,		:allow_null => false
			t.text		:file_path,		:allow_null => false
			t.integer	:at_time,		:default => 0
		end
		
		#
		# Media sharing support
		#
		create_table :group_medias do |t|
			t.references :group,	:allow_null => false
			t.references :media,	:allow_null => false
		end
		
		GroupMedia.reset_column_information
		Media.find_each do |media|
			gm = GroupMedia.new
			gm.group_id = media.group_id
			gm.media_id = media.id
			gm.save
		end
		remove_column :medias, :group_id
		add_column	:medias, :user_id, :integer	# Who uploaded a certain bit of media
		add_column	:medias, :interactive, :integer	# Timeout reset for interactivity (beyond the initial timeout)
		
		
		remove_column :playlist_medias, :end_time
		remove_column :playlist_medias, :pub_end_time
		add_column :playlist_medias, :transition_effect, :integer,	:allow_null => false, :default => 0
		add_column :playlist_medias, :pub_transition_effect, :integer,	:allow_null => false, :default => 0
		rename_column :playlist_medias, :media_id, :group_media_id
		PlaylistMedia.reset_column_information
		PlaylistMedia.find_each do |pm|			# we can do this as media wasn't shareable till now
			pm.group_media_id = GroupMedia.where(:media_id => pm.group_media_id).pluck(:id).first
			pm.save
		end
		
		remove_column :histories, :email
		
		create_table :stats do |t|
			t.references	:display,		:allow_null => false
			t.references	:media
			t.integer		:displayed,		:allow_null => false,	:default => 0
			t.integer		:error_count,	:allow_null => false,	:default => 0
			t.integer		:interacted,	:allow_null => false,	:default => 0
			t.integer		:displayed_for,	:allow_null => false,	:default => 0
			t.string		:last_error
		end
		
		
		#
		# Clean out the old conversion support information
		#
		FileConversion.destroy_all
		AcceptsFile.destroy_all
		
		#
		# TODO:: Replace with the new stuff or create a seed file
		#
		
	end
	
	def down
	end
end
