class ScheduleDisplayAdd < Struct.new(:display_group_id, :display_id, :old_group)
	def perform
		
		display = Display.find(display_id)
		
		Display.transaction do
			DisplaySchedule.joins(:schedule).where('display_schedules.display_id = ? AND schedules.display_group_id = ?', display_id, old_group).destroy_all unless old_group.nil?
			
			Schedule.where(:display_group_id => display_group_id).find_each do |schedule|
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
