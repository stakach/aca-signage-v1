
class ScheduleEndJob < Struct.new(:scheduled_id)
	def perform
		
		job = ScheduledJob.find(scheduled_id)
		
		
		Schedule.transaction do
			job.delete
			
			#
			# Check if the parent schedules are valid
			#
			schedules = Schedule.where(:do_end => job.schedule_time)
			
			schedules.find_each do |schedule|
				update_schedule(schedule)
			end
			
			#
			# Check if the display schedules are valid
			#
			displaySchedules = DisplaySchedule.where(:do_end => job.schedule_time)
			
			displaySchedules.find_each do |schedule|
				update_schedule(schedule)
			end
		end
		
	
	rescue ActiveRecord::RecordNotFound => e
		#
		# Schedule removed, we don't need to worry :)
		#
	end
	
	
	def update_schedule(schedule)
		schedule.save	# Runs validation which moves the time forward
		
		#
		# This indicates that the schedule has ended
		#
		if schedule.errors.present?
			schedule.destroy			# We don't need to invalidate caches (this job will be destroyed here)
		end
	end
	
	
	def error(job, exception)
		Airbrake.notify(exception) unless exception.class == ActiveRecord::ReadOnlyRecord		# This only happens some times and not on the re-run
	end
end
