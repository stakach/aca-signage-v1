class Timezone < ActiveRecord::Migration
	def up
		add_column :users, :timezone, :string
		
		User.reset_column_information
		User.update_all :timezone => 'Sydney'
	end

	def down
		remove_column :users, :timezone
	end
end
