class AltVideo < ActiveRecord::Migration
	def up
	
		#
		# New media columns
		#
		rename_column :medias, :original_path, :alt_path
		add_column :medias, :alt_type, :string
		add_column :medias, :media_type, :integer
		
		#
		# Update the existing data
		#
		#Media.reset_column_information
		#Media.where("LOWER(content_type) LIKE ?", '%url%').update_all(:media_type => 0)
		#Media.where("LOWER(content_type) NOT LIKE ?", '%url%').update_all(:media_type => 1)
		#Media.update_all(:alt_path => nil)
		
		#
		# Add an enforcing policy to the existing data
		#
		change_column :medias, :media_type, :integer, {:null => false}
		
		#
		# Priorities for file conversions
		#
		add_column :file_conversions, :ordinal, :integer
	end

	def down
		remove_column :file_conversions, :ordinal
		remove_column :medias, :media_type
		remove_column :medias, :alt_type
		rename_column :medias, :alt_path, :original_path
	end
end
