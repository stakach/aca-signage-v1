class Plugin < ActiveRecord::Base
	
	has_many :medias,		:dependent => :destroy
	
	
	#
	# When converting to json don't include the root element (:video => {})
	#
	self.include_root_in_json = false
	
	
	#
	# TODO:: group related plugins need to be found too
	#
	def self.search(group, search_terms = nil)
		#groups = group.self_and_ancestors.pluck(:id)
		result = Plugin.scoped	# .where('group_id IS NULL || group_id IN (?)', groups)
		
		if(search_terms.present?)
			search = '%' + search_terms.chomp.gsub(' ', '%').downcase + '%'
			result = result.where('LOWER(name) LIKE ? OR LOWER(help) LIKE ?', search, search)
		end
		
		return result
	end
	
	
	protected
	
	
	validates_presence_of :name
	
end
