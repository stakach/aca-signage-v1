class GroupDisplay < ActiveRecord::Base
	belongs_to :group
	belongs_to :display
	
	scope :for_group, lambda { |group| where("group_displays.group_id = ?", group.id) }
	
	
	after_destroy :check_display		# if this is the last display then we want to remove the display entry too
	
	
	def subgroup_id
		return nil
	end
	
	def subgroup_id=(something)
		return nil
	end
	
	
	protected
	
	
	#
	# If there are no other users using this display we should remove it
	#
	def check_display
		if !GroupDisplay.where(:display_id => self.display_id).exists?
			Display.destroy(self.display_id)
		end
	end
	
	
	validates :group_id, :uniqueness => {:scope => :display_id,	:message => "This display is already shared with that group"}
end
