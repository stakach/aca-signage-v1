class GroupMedia < ActiveRecord::Base
	
	belongs_to :group
	belongs_to :media
	
	before_destroy :update_playlists
	
	has_many :playlist_medias,	:dependent => :delete_all 	# IMPORTANT that this is after the before_destroy
	has_many :playlists,		:through => :playlist_medias
	
	after_destroy :check_media		# if this is the last media reference then we want to remove the display entry too
	
	
	
	scope :for_group, lambda { |group| where("group_medias.group_id = ?", group.id) }
	
	
	protected
	
	
	#
	# If there are no other users using this media item we should remove it
	#
	def check_media
		if !GroupMedia.where(:media_id => self.media_id).exists?
			Media.destroy(self.media_id)
		end
	end
	
	
	def update_playlists
		playlists = self.playlist_medias.where(:published => true).uniq.pluck(:playlist_id)
		if playlists.present?
			Delayed::Job.enqueue GroupMediaDestroyed.new(playlists), :queue => 'schedule', :run_at => 2.seconds.from_now
		end
	end
	
	
	validates_presence_of :group_id, :media_id
	validates :group_id, :uniqueness => {:scope => :media_id,	:message => "This is already shared with that group"}
	
end
