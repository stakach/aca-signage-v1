require 'base64'

class AddingGroups < ActiveRecord::Migration
	def up
		create_table :groups do |t|
			t.integer 		:parent_id		# Management structures (custom to this app)
			
			t.string	:identifier		# This is not used in the cloud
			t.string	:description,	:allow_null => false
			t.string	:timezone
			
			t.string	:domain				# As we want to map authentication to domains
			
			t.text		:notes
			t.timestamps
		end
		
		
		#
		# Group management tree
		#
		create_table :group_hierarchies, :id => false do |t|
			t.integer  :ancestor_id,	:null => false	# ID of the parent/grandparent/great-grandparent/... tag
			t.integer  :descendant_id,	:null => false	# ID of the target tag
			t.integer  :generations,	:null => false	# Number of generations between the ancestor and the descendant. Parent/child = 1, for example.
	    end
	    
	    # For "all progeny of..." selects:
	    add_index :group_hierarchies, [:ancestor_id, :descendant_id], :unique => true
	    
	    # For "all ancestors of..." selects
	    add_index :group_hierarchies, [:descendant_id]
	    
	    
		
		
		create_table :user_groups do |t|
			t.references	:group
			t.references	:user
			
			t.integer		:permissions,		:allow_null => false, :default => 0
			t.text		:notes
			t.timestamps
		end
		
		
		
		#
		# Remove auth sources
		#
		drop_table :auth_sources
		
		
		#
		# Add the other auth tables
		#
		 create_table :invites do |t|
			t.integer :group_id
			t.integer :permissions
			t.string :email
			t.string :secret
			t.datetime :expires
			t.text :message
			
	      t.timestamps
	    end
	    
	    
	    create_table :identities do |t|
	      t.string :email
		  t.string :password_digest
	
	      t.timestamps
	    end
	    
	    
	    create_table :authentications do |t|
		  t.integer :user_id
	      t.string :provider
	      t.string :uid
	      t.timestamps
	    end
		
		
		
		#
		# Transfer existing users to their equivalent group
		#
		Group.reset_column_information
		User.reset_column_information
		User.all.each do |user|
			group = Group.new
			group.id = user.id
			group.identifier = user.identifier
			group.description = user.description
			group.notes = user.notes
			group.save!
		end
		
		
		User.destroy_all
		remove_column	:users, :admin
		remove_column	:users, :privilege_map
		remove_column	:users, :auth_source_id
		remove_column	:users, :description
		remove_column	:users, :notes
		add_column		:users, :firstname, :string
		add_column		:users, :lastname, :string
		add_column		:users, :login_count, :integer,	:allow_null => false,	:default => 0
		
		
		
		
		#
		# Update the table names
		#
		rename_column 	:playlists, :user_id, :group_id
		rename_column	:user_displays, :user_id, :group_id
		rename_column	:medias, :user_id, :group_id
		rename_column	:display_groups, :user_id, :group_id
		rename_table 	:user_displays, :group_displays
	    
	    
	    #
	    # History table update (rename reserved word)
	    #
	    rename_column	:histories, :table, :table_name
	    
	    #
	    # Add permalink support for custom urls
	    # Displays now have a type (use parameterize function)
	    #
	    add_column		:displays, :permalink, :string
	    add_column		:displays, :physical, :boolean, :null => false, :default => true
	    add_column		:displays, :forward_back, :boolean, :null => false, :default => false
		add_column		:displays, :geolocate, :boolean, :null => false, :default => false
	    add_column		:displays, :max_space, :integer, :null => false, :default => 0
	    add_column		:displays, :wdays, :integer, :null => false, :default => 0b1111111	# Week day hash the display should be online
	end

	def down
	end
end
