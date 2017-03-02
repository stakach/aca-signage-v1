class Playlist < ActiveRecord::Base
	belongs_to :group
	belongs_to :display_group	# Optional
	has_many :playlist_medias,	:dependent => :delete_all 	# delete is correct as destroy is for media deletion
	has_many :published_medias, :foreign_key => "playlist_id", :class_name => "PlaylistMedia", :conditions => { :published => true }
	has_many :preview_medias, :foreign_key => "playlist_id", :class_name => "PlaylistMedia", :conditions => { :deleted => false }
	
	has_many :schedules,		:dependent => :destroy
	
	
	before_destroy	:update_groups
	after_save		:update_displays # (publish changes are now done in playlist job)
	
	
	has_many :display_groups,	:dependent => :nullify			# IMPORTANT this must be after before_destroy :update_groups
	has_many :displays,			:through => :display_groups
	
	
	self.include_root_in_json = false
	
	
	scope :live_on, lambda { |display| 
		select('DISTINCT "playlists".*')
			.joins('LEFT OUTER JOIN "schedules" ON "playlists"."id" = "schedules"."playlist_id"')
			.joins('LEFT OUTER JOIN "display_caches" ON "schedules"."id" = "display_caches"."schedule_id"')
			.joins('LEFT OUTER JOIN "display_groups" ON "playlists"."id" = "display_groups"."playlist_id"')
			.joins('LEFT OUTER JOIN "display_groupings" ON "display_groups"."id" = "display_groupings"."display_group_id"')
			.where('"display_caches"."display_id" = ? OR "display_groupings"."display_id" = ?', display.id, display.id)
	}
	
	
	
	def search(search_terms = nil)
		if(search_terms.nil? || search_terms == "")
			playlist_medias.raw
		else
			search = '%' + search_terms.chomp.gsub(' ', '%').downcase + '%'
			playlist_medias.raw.joins(:media).where('LOWER(medias.name) LIKE ? OR LOWER(medias.comment) LIKE ?', search, search)
		end
	end
	
	
	#
	# Publish any changes made to a playlist (this should be in the playlist model)
	#
	def publish
		Playlist.transaction do
			self[:published_at] = Time.now
			save!(:validate => false)
			Delayed::Job.enqueue PlaylistPublish.new(self.id), :queue => 'schedule'
		end
	end
	
	
	def cancel_publish
		Playlist.transaction do
			PlaylistMedia.cancel_publish(id)		# We are not doing this in the background as the view needs to change
			self[:published_at] = Time.now
			save!
		end
	end
	
	
	def publish_pending?
		return false unless self.playlist_medias.where('playlist_medias.updated_at > ?', self.published_at).exists?
		return true
	end
	
	
	def last_updated	# for playlist preview
		self.preview_medias.order("updated_at DESC").pluck(:updated_at).first || Time.now
	end
	
	
	
	#
	# After change we need to update the playlists that will be effected
	# => Also used by Media on_update
	#
	def update_displays(override = false)
		if override || self.default_timeout_changed? || self.random_changed?
			thetime = Time.now
			update_groups(thetime)
			Display.joins(:display_caches).joins('INNER JOIN schedules ON display_caches.schedule_id = schedules.id').where('schedules.playlist_id = ?', self.id).update_all(:last_updated => thetime)
		end
	end
	

	protected
	
	
	#
	# Destroy will destroy the schedules who will deal with cache update
	#
	def update_groups(thetime = Time.now)
		self.displays.update_all(:last_updated => thetime)
	end
	
	
	validates_presence_of :name, :group
	validates_numericality_of :default_timeout, :only_integer => true, :message => I18n.t(:invalid_playlist_timeout)
end
