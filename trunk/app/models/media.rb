require 'uri'


class Media < ActiveRecord::Base
	has_many :thumbnails,	:dependent => :destroy
	has_many :formats,		:dependent => :destroy
	
	belongs_to :plugin
	
	
	after_save		:check_displays
	
	
	has_many :group_medias,		:dependent => :destroy
	has_many :playlist_medias,	:through => :group_medias
	has_many :playlists,		:through => :playlist_medias
	#has_many :schedules,		:through => :playlists
	#has_many :display_caches,	:through => :schedules
	
	
	#
	# When converting to json don't include the root element (:video => {})
	#
	self.include_root_in_json = false
	
	
	#
	# Media type quick lookup
	#
	MEDIA_TYPES = {
		:other => -1,
		:image => 0,
		:video => 1,
		:audio => 2,
		:plugin => 10,
		:url => 11,
		:image_url => 12,
		'image' => 0,
		'video' => 1,
		'audio' => 2,
		'plugin' => 10,
		'url' => 11,
		'image_url' => 12,
		-1 => :other,
		0 => :image,
		1 => :video,
		2 => :audio,
		10 => :plugin,
		11 => :url,
		12 => :image_url
	}
	
	ADD_OPTIONS = [					# The list of manual add items
		[:media_select_web, 0],
		[:media_select_plugin, 1],
		[:media_select_file, 2]		# Use HTML5 multi-select upload if available (v5)
	]
	
	
	#
	# File conversions are triggered here
	#
	before_validation	:set_type
	before_create		:check_state
	after_create		:check_media
	after_destroy		:delete_file
	
	
	scope :for_group, lambda { |group| joins(:group_medias).where('group_medias.group_id = ?', group.id) }
	
	
	def self.search(group, search_terms = nil)
		result = Media.for_group(group)
		
		if(!search_terms.nil? && search_terms != "")
			search = '%' + search_terms.chomp.gsub(' ', '%').downcase + '%'
			result = result.where('LOWER(name) LIKE ? OR LOWER(comment) LIKE ?', search, search)
		end
		
		return result
	end
	
	
	
	#
	# Return the workflow state in the correct language
	#
	def state
		case self.workflow_state.to_sym
			when :checking then 'checking'
			when :converting then I18n.t(:media_work_converting)
			when :ready then I18n.t(:media_work_ready)
			when :error then I18n.t(:media_work_error)
			when :invalid then 'invalid'
		end
	end
	
	#
	# Is it an image, video etc
	#
	def classification
		case MEDIA_TYPES[media_type]
			when :other then 'other'
			when :image then 'image'
			when :video then 'video'
			when :audio then 'audio'
			when :plugin then 'plugin'
			else 'url'
		end
	end
	
	def type
		MEDIA_TYPES[media_type]
	end
	
	
	
	#
	# Conversion monitoring code
	#
	include Workflow
	workflow do
		state :checking do	# Default state
			event :converting,		:transitions_to => :converting
			event :failure,			:transitions_to => :error
			event :bad,				:transitions_to => :invalid
			event :complete,		:transitions_to => :ready
		end
		
		state :converting do
			event :failure,			:transitions_to => :error
			event :complete,		:transitions_to => :ready
			event :recheck,			:transitions_to => :checking
		end
		
		state :ready do
			event :converting,		:transitions_to => :converting
		end
		
		state :error do
			event :try_again,		:transitions_to => :checking
		end
		
		state :invalid do 	# Was unable to inspect the file (probably corrupt or bad)
			event :try_again,		:transitions_to => :checking
		end
	end
	
	
	#
	# Functions for setting the required fields
	#
	def uploaded_file=(file)
		if self.new_record? && !file.nil?
			sanitize_filename(file.original_filename)		# sets self.original_file
			if self.name.nil? || self.name.empty?			# Ensures a name has been set
				self.name = file.original_filename
			end
			
			if AcceptsFile.supports(File.extname(self.file_path)).nil?
				if FileConversion.applies(self.file_path).count > 0
					FileUtils.cp file.tempfile.path, self.file_path	# file copy here
					FileUtils.chmod 0666, self.file_path
				else
					self.file_path = nil	# This file is not supported
				end
			else
				FileUtils.cp file.tempfile.path, self.file_path	# file copy here
				FileUtils.chmod 0666, self.file_path	# Ensure everyone can read it
			end
		end
	end
	
	
	def url_path
		return '' if media_type.nil?
		return file_path.sub('public', '') unless media_type > 10
		return file_path
	end
	
	def url_path=(uri)
		#
		# Get file extension
		# TODO:: use uri to do this (we can validate the URI here too)
		#
		ext = File.extname(uri)
		index = ext.index(/[?#]/)
		if index.present?
			index = index - 1
			ext = ext[0..index]
		end
		
		#
		# Check if the file is supported
		#
		accept = AcceptsFile.supports(ext)
		if accept.present? && accept.mime =~ /image/
			self.media_type = 12 # image_url (special as will not be viewed in an iframe)
		else
			self.media_type = 11 # URL
		end
		
		#
		# Set the fields
		#
		self.name = uri unless self.name.present?
		self.file_path = uri
	end
	
	
	#
	# Takes either full paths or file names and returns only a file name with
	#        web safe characters
	#
	def sanitize_filename(filename)
		# get only the filename, not the whole path
		filename = filename.gsub(/^.*(\\|\/)/, '')
		# NOTE: File.basename doesn't work right with Windows paths on Unix
		# INCORRECT: just_filename = File.basename(value.gsub('\\\\', '/'))
		
		# Finally, replace all non alphanumeric or periods with underscore
		filename = "#{Time.now.to_f.to_s.sub('.', '')}#{rand(100)}#{File.extname(filename.gsub(/[^\w\.\-]/,'_'))}"
		filepath = "public/uploads/#{self.user_id}"
		
		FileUtils.makedirs filepath
		FileUtils.chmod 0777, filepath	# Directory should have execute
		self.file_path = File.join(filepath, filename)
	end
						  
						  
	#
	# This triggers the task to check the media format (if required)
	#
	def check_media
		#
		# This is a URL
		#
		if self.media_type < 10
			Delayed::Job.enqueue CheckMediaJob.new(self.id), :queue => 'checking'
		end
	end
	
	
	protected
	
	#
	# mark playlists as un-published after update (if a URL)
	#
	def check_urls
		if self.file_path_changed?
			self.playlist_medias.update_all(:updated_at => Time.now)
		end
	end
	
	
	def set_type
		if self.media_type.nil?
			#
			# determine the media type and set it here!
			# TODO::  This will also need to happen during migrations
			#
			if self.plugin_id.present?
				self.media_type = 10 # plugin!!
			else
				ext = File.extname(self.file_path)
				accept = AcceptsFile.supports(ext)
				if accept.present?
					self.media_type = MEDIA_TYPES[accept.mime.split('/')[0].to_sym]
				else
					#
					# Look up the conversions
					#
					accept = FileConversion.applies(self.file_path).first
					if accept.present? && accept.accepts_file_id.present?
						self.media_type = MEDIA_TYPES[accept.accepts_file.mime.split('/')[0].to_sym]
					else
						self.media_type = -1 # Other!! (PPT etc 2 stage conversion)
					end
				end
			end
		end
	end
	
	
	def check_state
		if self.media_type >= 10
			self.workflow_state = 'ready'
		end
	end
						  
	
	#
	# This job will attempt to delete the file multiple times
	#
	def delete_file
		if self.media_type.nil? || self.media_type < 10
			Delayed::Job.enqueue DeleteFileJob.new(self.file_path), :queue => 'delete', :run_at => 5.minutes.from_now
		end
	end
	
	
	#
	# Updates displays if a URL or Plugin data has changed
	#
	def check_displays
		if (self.file_path_changed? || self.background_changed?) && self.playlists.exists?
			Delayed::Job.enqueue MediaUpdated.new(self.id), :queue => 'schedule'
		end
	end
	
	
	#
	# Validations
	#
	validates_presence_of :file_path, :name
	validates_presence_of :media_type, :allow_nil => false, :message => 'Unsupported format'
	validate :plugin_validation, :if => Proc.new { |a| a.media_type.present? && a.media_type == 10 }
	validates_format_of :file_path, :with => URI::regexp(%w(http https)), :message => 'Invalid URL format', :if => Proc.new { |a| a.media_type.present? && a.media_type > 10}
	
	def plugin_validation
		if self.file_path.present? && self.plugin.requires_data && self.plugin.validation.present?
			errors.add(:plugin, "Invalid plugin data") unless self.file_path.scan(/#{self.plugin.validation}/i).empty?
		end
	end
end




