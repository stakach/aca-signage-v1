class ScheduleDisplayTimezone < Struct.new(:display_id)
	def perform
		
		display = Display.find(display_id)
		display.display_caches.delete_all
		display.display_schedules.destroy_all
		
		Display.transaction do
			display.schedules.find_each do |schedule|
				ds = DisplaySchedule.new(:display_id => display.id, :schedule_id => schedule.id)
				if schedule.sync_all_zones
					ds.do_end = schedule.do_end
					ds.do_start = schedule.do_start
				else
					zone = display.timezone
					ds.do_end = schedule.do_end.new_zone(zone)
					ds.do_start = schedule.do_start.new_zone(zone)
				end
				ds.save
			end
			
			display.update_attribute(:last_updated, Time.now)
		end
		
	
	rescue ActiveRecord::RecordNotFound => e
		#
		# Schedule removed, we don't need to worry :)
		#
	end
	
	def error(job, exception)
		Airbrake.notify(exception)
	end
end
