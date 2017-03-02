class InitDb < ActiveRecord::Migration
	def up
	
		create_table :auth_sources do |t|
			t.string	:type,	:allow_null => false
			t.string	:name,	:allow_null => false
			t.string	:host
			t.integer	:port
			t.string	:account
			t.string	:account_password
			t.string	:base_dn
			t.string	:attr_login
			t.string	:attr_firstname
			t.string	:attr_lastname
			t.string	:attr_mail
			t.string	:attr_member
			t.boolean	:tls
		end
	
		create_table :users do |t|
			t.references :auth_source,	:allow_null => false
			
			t.string	:identifier,	:allow_null => false
			t.boolean	:admin,		:default => false
			t.integer	:status,		:default => 0
			
			t.timestamps
		end
	
		create_table :playlists do |t|
			t.references	:user,		:allow_null => false
			
			t.string		:name,		:allow_null => false
			t.text		:comment
			t.integer		:default_timeout,	:default => 30
			t.datetime		:published_at,	:default => Time.now
			t.datetime		:published_new,	:default => Time.now		# New content (as screens will reload)
			
			t.timestamps
		end
	
		create_table :display_groups do |t|
			t.references	:playlist
			t.references	:user,	:allow_null => false
			
			t.string		:name,	:allow_null => false
			t.text		:comment
			
			t.timestamps
		end
		
		create_table :displays do |t|
			t.string	:name,	:allow_null => false
			t.string	:building,	:allow_null => false
			t.string	:location,	:allow_null => false
			t.text	:comment
			t.text	:link
			
			t.timestamps
		end
		
		
		#
		# This allows a display to belong to more than one display group
		#
		create_table :display_groupings do |t|
			t.references	:display_group,	:allow_null => false
			t.references	:display,		:allow_null => false
		end
		
		#
		# This allows a display to belong to more than one group of users
		#
		create_table :user_displays do |t|
			t.references	:user,	:allow_null => false
			t.references	:display,	:allow_null => false
		end
		
		create_table :medias do |t|
			t.references :user,		:allow_null => false
		
			t.string	:name,		:allow_null => false
			t.string	:comment
			
			#
			# Can be file or a URL (content_type should be inspected)
			#
			t.string	:content_type,	:allow_null => false
			t.text	:path,		:allow_null => false
			t.text	:original_path					# Not used yet
			
			t.string	:workflow_state
			
			t.timestamps
		end
		
		#
		# The media being applied to playlists
		#
		create_table :playlist_medias do |t|
			t.references :media,		:allow_null => false
			t.references :playlist,		:allow_null => false

			#
			# Timout of 0 means play to end and only applies to HTML5 Video Content
			#
			t.integer	:run_time
			t.integer	:start_time		# For HTML5 Video
			t.integer	:end_time
			t.integer	:ordinal		# Order in playlist
			
			#
			# So we can rotate changes smoothly we must publish changes to a playlist
			#	
			t.boolean	:deleted,		:default => false
			t.boolean	:published,		:default => false
			
			t.integer	:pub_run_time
			t.integer	:pub_start_time
			t.integer	:pub_end_time
			t.integer	:pub_ordinal
			
			t.timestamps
		end
		
		create_table :accepts_files do |t|
			t.string	:ext,		:allow_null => false
			t.string	:mime,	:allow_null => false
			
			t.boolean	:enabled
		end
		
		
		create_table :file_conversions do |t|
			t.references :accepts_file,	:allow_null => false
			
			t.string	:applies_to,	:allow_null => false
			t.text	:command,		:allow_null => false
			t.string	:description,	:allow_null => false
			t.boolean	:enabled,		:default => true
			
			t.timestamps
		end
		
		
		create_table :histories do |t|
			t.references :user,	:allow_null => false
			
			t.string	:table,	:allow_null => false	# Table name
			t.integer	:table_id,	:allow_null => false
			t.boolean	:deleted,	:default => false		# Was the column deleted
			t.text	:changes,	:allow_null => false	# XML of changes made
			
			t.timestamps
		end
	end

	def down
		drop_table :accepts_files
		drop_table :histories
		drop_table :file_conversions
		drop_table :playlist_medias
		drop_table :medias
		drop_table :user_displays
		drop_table :display_groupings
		drop_table :displays
		drop_table :display_groups
		drop_table :playlists
		drop_table :users
		drop_table :auth_sources
	end
end
