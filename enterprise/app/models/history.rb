class History < ActiveRecord::Base

	# TODO: Write a module to save history for various tables
	def do_audit(record, type, user_id)
		self.table_name = record.class.to_s
		self.table_id = record.id
		self.user_id = user_id

		if type == :deleted
			self.deleted = true
		else
			self.deleted = false
		end
		
		if type != :update
			self[:objectxml] = record.to_xml
		else
			self[:objectxml] = record.changes.to_xml
		end
		
		self.save!
	end
end
