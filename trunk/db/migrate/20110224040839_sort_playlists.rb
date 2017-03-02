class SortPlaylists < ActiveRecord::Migration

	def up
		add_column :playlists, :display_group_id, :integer
	end

	def down
		remove_column :playlists, :display_group_id
	end
end
