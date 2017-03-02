class EmailFailures < ActiveRecord::Migration
	def up
		add_column :displays, :last_emailed, :datetime	# To prevent multiple emails being sent
		add_column :displays, :window_start, :datetime
		add_column :displays, :window_end, :datetime
		add_column :displays, :notify_offline, :boolean, {:null => false, :default => false}
		add_column :displays, :timezone, :string
		
		#Display.reset_column_information
		#Display.update_all :timezone => 'Sydney'
	end

	def down
		remove_column :displays, :last_emailed
		remove_column :displays, :window_start
		remove_column :displays, :window_end
		remove_column :displays, :notify_offline
		remove_column :displays, :timezone
	end
end
