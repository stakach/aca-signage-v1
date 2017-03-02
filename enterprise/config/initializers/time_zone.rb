module ActiveSupport
	class TimeWithZone
		def new_zone(n_zone)
			# Reinitialize with the new zone and the local time
			TimeWithZone.new(nil, ActiveSupport::TimeZone[n_zone], time)
		end
	end
end
