class PlaylistMedia < ActiveRecord::Base

	belongs_to :group_media
	has_one :media, :through => :group_media
	belongs_to :playlist
	
	has_many :display_groups, :through => :playlist
	
	scope :is_published, where(:published => true).order('playlist_medias.pub_ordinal ASC')
	scope :raw, where(:deleted => false).order('playlist_medias.ordinal ASC')	# The un-published works
	
	
	after_initialize :breakdown_time
	before_create	:set_order
	
	
	#
	# Update order command sent from controller (expect an array of ids in the order required)
	#	Makes use of publish
	#
	#	Same as file conversion
	#
	def self.order_all(ids)
		#
		# by using the sql case statement we only hit the database once
		#	Scales better.
		#
		sql = "UPDATE playlist_medias SET updated_at = '#{Time.now.utc.to_s(:db)}', ordinal = CASE id "
		ids.each_with_index do |id, index|
			sql += "WHEN #{id} THEN #{index} "
		end
		sql += "END WHERE id IN (#{ids.join(',')})"
		connection.execute(sql)
		
		#
		# N DB requests is slow (only use if not supported in DB)
		#
		#PlaylistMedia.transaction do
		#	ids.each_with_index do |id, index|
		#		item = PlaylistMedia.update(id, :ordinal => index)
		#	end
		#end
	end
	
	
	
	#
	# Hours Min Seconds breakdown for run time editing
	#
	attr_reader :hours
	attr_reader :minutes
	attr_reader :seconds
	
	def hours=(h)
		@hours = h.to_i
		setTimeout
	end
	
	def minutes=(m)
		@minutes = m.to_i
		setTimeout		
	end
	
	def seconds=(s)
		@seconds = s.to_i
		setTimeout
	end
	
	def run_time	# Display current run time
		breakdown_time
		
		if (([:video, :audio].include?(media.type)) || (:plugin == media.type && media.plugin.can_play_to_end)) && (self[:run_time].nil? || self[:run_time] == 0)
			return "Plays to end"
		end

		display = ''
		display_concat = ''

		if hours > 0
			display = display + display_concat + "#{hours}h"
			display_concat = ' '
		end
		if minutes > 0 || display.length > 0
			display = display + display_concat + "#{minutes}m"
			display_concat = ' '
		end
		display = display + display_concat + "#{seconds}s"
		display
	end
	
	
	#
	# Publish any changes to the playlist
	#
	def self.publish(playlist_id)
		PlaylistMedia.where('playlist_id = ? AND deleted = ?', playlist_id, true).delete_all 	# Delete is correct
		PlaylistMedia.where('playlist_id = ?', playlist_id).find_each do |item|
			item.attributes = {:published=>true, :pub_run_time => item[:run_time], :pub_start_time => item.start_time, :pub_ordinal => item.ordinal, :pub_transition_effect => item.transition_effect}
			item.save!
		end
	end
	
	#
	# Cancel changes
	#
	def self.cancel_publish(playlist_id)
		PlaylistMedia.where('playlist_id = ? AND published = ?', playlist_id, false).delete_all
		PlaylistMedia.where('playlist_id = ?', playlist_id).find_each do |item|
			item.attributes = {:deleted=>false, :run_time => item.pub_run_time, :start_time => item.pub_start_time, :ordinal => item.pub_ordinal, :transition_effect => item.pub_transition_effect}
			item.save!
		end
	end
	
	
	protected
	
	
	
	#
	# Calculate hours min seconds
	#
	def setTimeout		# Time item will play for
		self[:run_time] = @hours * 3600 + @minutes * 60 + @seconds
	rescue
		@hours = 0 if @hours.nil?
		@minutes = 0 if @minutes.nil?
		@seconds = 0 if @seconds.nil?
		setTimeout
	end
	
	
	def breakdown_time	# For editing timeouts
		return if $rails_rake_task
		
		total_seconds = self[:run_time]
		
		if total_seconds.nil? || total_seconds == 0
			if [:video, :audio].include?(media.type) || (:plugin == media.type && media.plugin.can_play_to_end)
				total_seconds = 0
			else
				total_seconds = playlist.default_timeout
			end
		end
		
		#@days = total_seconds / 86400
		@hours = total_seconds / 3600 #- (days * 24)
		@minutes = total_seconds / 60 - (@hours * 60) #- (days * 1440)
		@seconds = total_seconds % 60
	end
	
	
	def set_order		# On create
		self[:ordinal] = playlist.playlist_medias.maximum(:ordinal)
		if self[:ordinal].class != Fixnum
			self[:ordinal] = -1
		end
		self[:ordinal] = self[:ordinal] + 1
		
		self[:transition_effect] = self.playlist.default_transition
	end

end
