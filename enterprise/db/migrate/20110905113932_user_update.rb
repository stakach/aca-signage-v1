class UserUpdate < ActiveRecord::Migration
	def change
		rename_column :users, :status, :privilege_map
		add_column :users, :system_admin, :boolean,	:allow_null => false,	:default => false	# Access to everything. Privilege map still stands
	end
end
