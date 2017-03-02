class LastUpdated < ActiveRecord::Migration
	
	#
	# Display (Allow updating of displays last_updated times directly)
	# => If an active schedule is occuring on a display group, other than the one the display is being removed from, update that last_updated time too
	# Display Group => Schedule (Active schedules overwrite display groups last updated time)
	# Playlist => Playlist always has the latest time (think about this some more)
	#
	def up
		add_column :display_groups, :last_updated, :datetime, :default => '2000-01-01 00:00:00'
		add_column :displays, :force_update, :datetime, :default => '2000-01-01 00:00:00'
	end
	
	def down
		remove_column :display_groups, :last_updated
		remove_column :displays, :force_update
	end
end
