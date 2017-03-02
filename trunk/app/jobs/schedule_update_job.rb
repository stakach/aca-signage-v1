
class ScheduleUpdateJob < Struct.new(:schedule_id)
	def perform
		
		schedule = Schedule.find(schedule_id)
		
		Schedule.transaction do
			schedule.displays.find_each do |display|
				ds = DisplaySchedule.where(:display_id => display.id, :schedule_id => schedule.id).first_or_initialize

				if schedule.sync_all_zones
					ds.do_end = schedule.do_end
					ds.do_start = schedule.do_start
				else
					zone = display.timezone
					ds.do_end = schedule.do_end.new_zone(zone)
					ds.do_start = schedule.do_start.new_zone(zone)
				end
				
				ds.save
				if ds.errors.present? && !ds.new_record?
					ds.destroy
				end
			end
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
