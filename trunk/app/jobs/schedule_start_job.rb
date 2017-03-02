
class ScheduleStartJob < Struct.new(:scheduled_id)
	def perform
		
		schedule = ScheduledJob.find(scheduled_id)	# delete is correct
		schedule.delete
		
		#
		# Update display cache for all the effected displays
		#
		Display.joins(:display_schedules).where('display_schedules.do_start = ?', schedule.schedule_time).find_each do |display|	# find_each won't thrash the DB
			display.update_cache
		end
		
	
	rescue ActiveRecord::RecordNotFound => e
		#
		# Schedule removed, we don't need to worry :)
		#
	end
	
	def error(job, exception)
		Airbrake.notify(exception) unless exception.class == ActiveRecord::ReadOnlyRecord		# This only happens some times and not on the re-run
	end
end
