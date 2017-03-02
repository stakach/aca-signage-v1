
class ScheduleCacheUpdate < Struct.new(:display_id, :force)
	def perform
		
		
		Display.find(display_id).update_cache(force)
		
	
	rescue ActiveRecord::RecordNotFound => e
		#
		# Group removed, we don't need to worry :)
		#
	end
	
	def error(job, exception)
		Airbrake.notify(exception) unless exception.class == ActiveRecord::ReadOnlyRecord		# This only happens some times and not on the re-run
	end
end
