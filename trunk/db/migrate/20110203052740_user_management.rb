class UserManagement < ActiveRecord::Migration
	def up
		#
		# Add a friendly name for every user group
		#	Identifier can be cryptic
		#
		add_column :users, :description, :string
		
		User.reset_column_information
		User.update_all "description = identifier"
	end

	def down
		remove_column :users, :description
	end
end
