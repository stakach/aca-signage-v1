class ScheduledJob < ActiveRecord::Base

	belongs_to :job,	:class_name => "Delayed::Backend::ActiveRecord::Job", :dependent => :delete
	
	
	after_create	:create_job
	
	# first_or_initialize => start_job = true, display_group = x, schedule_time = time at
	
	
	protected
	
	
	
	def create_job
		klass = self.start_job ? ScheduleStartJob : ScheduleEndJob
		self.job = Delayed::Job.enqueue klass.new(self.id), :queue => 'schedule', :run_at => self.schedule_time
		self.save!
	end
	

end
