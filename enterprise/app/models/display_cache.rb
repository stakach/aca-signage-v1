class DisplayCache < ActiveRecord::Base
	
	belongs_to :display,	:inverse_of => :display_caches
	belongs_to :schedule,	:inverse_of => :display_caches
	
	
	#
	# This is how we will minimise updates
	# Only update displays when:
	# => the cache is added to this list			(handled by display)
	# => the cache is removed before schedule end	(handled by schedule_cache_update)
	#
	# No need to update when:
	# => a cache is removed due to schedule end		(handled by schedule_end_job)
	#
	
	
	protected
	
	
	validates_presence_of :display, :schedule
	
end
