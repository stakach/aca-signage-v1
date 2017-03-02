class AddNotesToUsers < ActiveRecord::Migration
	def up
		add_column :users, :notes, :text
	end

	def down
		remove_column :users, :notes
	end
end
