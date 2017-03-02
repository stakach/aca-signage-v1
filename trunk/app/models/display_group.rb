class DisplayGroup < ActiveRecord::Base
	#
	# Users
	#
	belongs_to :group
	
	#
	# Displays
	#
	has_many :display_groupings,	:dependent => :destroy
	has_many :displays,				:through => :display_groupings
	
	#
	# Scheduled playlists
	#
	has_many :schedules,			:dependent => :destroy
	has_many :display_caches,		:through => :schedules
	has_many :current_schedules,	:through => :display_caches, :source => 'schedule', :class_name => "Schedule"
	
	#
	# Playlist
	#
	belongs_to :playlist	# Default playlist
	has_many :playlist_medias,	:through => :playlist
	
	#
	# Playlists grouped by schedule
	#
	has_many :playlists,		:dependent => :destroy
	
	#
	# Playlist IDs
	#
	scope :for_display, lambda {|disp| joins(:display_groupings).where("display_groupings.display_id = ? AND display_groups.playlist_id IS NOT NULL", disp) }
	
	
	after_update :update_displays
	
	
	self.include_root_in_json = false
	
	
	def search(search_terms = nil)
		if(search_terms.nil? || search_terms == "")
			display_groupings.joins(:display)
		else
			search = '%' + search_terms.chomp.gsub(' ', '%').downcase + '%'
			display_groupings.joins(:display).where('LOWER(displays.name) LIKE ? OR LOWER(displays.comment) LIKE ? OR LOWER(displays.building) LIKE ? OR LOWER(displays.location) LIKE ?', search, search, search, search)
		end
	end
	
	
	protected
	
	
	#
	# Makes sure manifest files are updated
	#
	def update_displays
		if self.playlist_id_changed?
			#
			# Do an update all on displays that are in this display group
			#
			self.displays.update_all(:last_updated => Time.now)
		end
	end
	
	
	validates_presence_of :name, :group
end
