class CreateSchedules < ActiveRecord::Migration
	def up
		create_table :schedules do |t|
			t.references :playlist,		:allow_null => false
			t.references :display_group,	:allow_null => false
			
			t.text	:notes
			t.boolean	:exclusive,	:default => false
			t.boolean	:emergency,	:default => false
			
			t.boolean	:all_day,	:default => false
			t.datetime	:do_start,	:default => Time.now
			t.datetime	:do_end,	:default => Time.now
			
			t.integer	:repeat_period,	:default => 0
			t.datetime	:end_repeat
			
			t.timestamps
		end
		
		#
		# Lets save the user email in the log
		#	Change column name as reserved by active record
		#
		add_column :histories, :email, :string,	:allow_null => false
		rename_column :histories, :changes, :objectxml
		
		#
		# Add an email for the manager of a user group
		#	Change default for active status to 1 as we will use this as a bit mask field now.
		#
		change_column_default(:users, :status, 1)
		add_column :users, :email, :string
		
		User.reset_column_information
		User.where('status = 0').update_all(:status => 1)	# active
		User.where('status = 1').update_all(:status => 0)	# locked
		
		#
		# Displays: Last_updated column to cache results accross requests (XML and Manifest)
		#
		add_column :displays, :last_updated, :datetime, :default => Time.now
	end

	def down
		drop_table :schedules
		remove_column :histories, :email
		remove_column :users, :email
		change_column_default(:users, :status, 0)
		#Users.where('status & 1 > 0').update_all(:status => 0)
		remove_column :displays, :last_updated
		rename_column :histories, :objectxml, :changes
	end
end
