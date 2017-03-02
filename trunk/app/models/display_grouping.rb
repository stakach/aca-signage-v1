class DisplayGrouping < ActiveRecord::Base

	belongs_to :display
	belongs_to :display_group
	has_many	:schedules,			:through => :display_group
	
	before_destroy	:destroy_schedules
	has_many		:display_schedules,	:through => :schedules, :conditions => proc { ["display_schedules.display_id = ?", display_id] }
	
	
	scope :for_display, lambda {|disp| where("display_id = ?", disp) }
	
	after_save		:check_update
	after_destroy	:update_display
	
	
	protected
	
	
	
	#
	# Force update display
	#  If there are no schedules the default playlist at the least needs to be updated
	#
	def update_display
		self.display.update_attribute(:last_updated, Time.now) if display_group.playlist_id.present?
	end
	
	
	def check_update
		if self.display_group_id_changed?
			#
			# Update display with new schedules
			#
			Delayed::Job.enqueue ScheduleDisplayAdd.new(self.display_group_id, self.display_id, self.display_group_id_was), :queue => 'schedule', :run_at => 2.seconds.from_now
		end
	end
	
	
	def destroy_schedules
		ids = self.display_schedules.pluck('display_schedules.id')
		DisplaySchedule.where('id IN (?)', ids).destroy_all
	end
	
	
	validates :display_group_id, :uniqueness => {:scope => :display_id,	:message => "This display is already in that schedule"}
end
