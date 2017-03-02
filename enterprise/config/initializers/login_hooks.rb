


#
# Mixes into the user model
#
Signage::Application.config.advanced_auth.group_mixin = proc do
	has_many :group_medias,			:dependent => :destroy
	has_many :playlists,		:dependent => :destroy,	:order => 'created_at DESC'
	has_many :display_groups,	:dependent => :destroy,	:order => 'created_at DESC'
	
	has_many :group_displays,	:dependent => :destroy
	has_many :displays,		:through => :group_displays
	
	
	self.include_root_in_json = false
	
	
	def self.search(user, search_terms = nil)
		result = Group.joins(:user_groups).where('user_groups.user_id = ?', user.id)
		
		if search_terms.present?
			search = '%' + search_terms.chomp.gsub(' ', '%').downcase + '%'
			result = result.where('LOWER(groups.identifier) LIKE ? OR LOWER(groups.domain) LIKE ? OR LOWER(groups.description) LIKE ? OR LOWER(groups.notes) LIKE ?', search, search, search, search)
		end
		
		return result
	end
	
	def self.sub_search(group, search_terms = nil, children_only = false)
		result = group.self_and_descendants unless children_only
		result = group.children if children_only
		
		if search_terms.present?
			search = '%' + search_terms.chomp.gsub(' ', '%').downcase + '%'
			result = result.where('LOWER(groups.identifier) LIKE ? OR LOWER(groups.domain) LIKE ? OR LOWER(groups.description) LIKE ? OR LOWER(groups.notes) LIKE ?', search, search, search, search)
		end
		
		return result
	end
	
	
	def timezone
		return self[:timezone] unless self[:timezone].nil?
		'Sydney'	# Default timezone
	end
	
	
	after_destroy	:remove_directory
	
	
	protected
	
	
	def remove_directory
		Dir.delete("public/uploads/#{self.id}") unless !File.directory?("public/uploads/#{self.id}")
	rescue
		# Unable to delete the directory as a file exists in it. No big loss
	end
	
	
	#validates_presence_of :identifier, :auth_source
	#validates_format_of :email, :with => /^([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})$/i, :allow_nil => true, :allow_blank => true
end


Signage::Application.config.advanced_auth.user_mixin = proc do
	has_many :histories,		:dependent => :destroy
	
	def self.search(group, search_terms = nil)
		result = User.joins(:user_groups).where('user_groups.group_id = ?', group.id)
		
		if search_terms.present?
			search = '%' + search_terms.chomp.gsub(' ', '%').downcase + '%'
			result = result.where('LOWER(users.email) LIKE ? OR LOWER(users.firstname) LIKE ? OR LOWER(users.lastname) LIKE ? OR LOWER(users.notes) LIKE ?', search, search, search, search)
		end
		
		return result
	end
	
	
	
	scope :alerts_for, lambda { |display|
		select('DISTINCT "users".*')
			.joins(:user_groups)
			.joins('INNER JOIN "group_displays" ON "user_groups"."group_id" = "group_displays"."group_id"')
			.where('("user_groups"."permissions" & ?) > 0 AND "group_displays"."display_id" = ?', AcaSignageSettings::SETTINGS[:display_alerts], display.id)
	}
	
	
	
	
	def timezone
		return self[:timezone] unless self[:timezone].nil?
		'Sydney'	# Default timezone
	end
end


module AcaSignageSettings
	
	SETTINGS = {
		:publisher => 0b1,				# User can create / destroy schedules and publish
		:admin => 0b10,					# User can create / destroy displays and publish / change other users permissions and invite / remove users
		:group_manager => 0b100,		# User can create sub-groups and invite / remove users from groups
		:domain_manager => 0b1000,		# User can add, remove or migrate signage domains (effects URLs, groups and logins)
		:display_alerts => 0b10000		# User would like to receive alerts related to screens
		# Expand to support more options if required
	}
	
	
	def user_desc
		if self.domain_manager?
			return 'Domain Manager'
		elsif self.group_manager?
			return 'Group Manager'
		elsif self.admin?
			return 'Administrator'
		elsif self.publisher?
			return 'Publisher'
		else
			return 'Producer'
		end
	end
	
	
	#
	# Bit mask accessors:
	#
	# Automatically creates a callable function for each command
	#	http://blog.jayfields.com/2007/10/ruby-defining-class-methods.html
	#	http://blog.jayfields.com/2008/02/ruby-dynamically-define-method.html
	#
	SETTINGS.each_key do |setting|
		setting_getter = "#{setting}?".to_sym
		setting_setter = "#{setting}=".to_sym
		
		define_method setting_getter do
			return false if self.permissions.nil?
			self.permissions & SETTINGS[setting] > 0
		end
		define_method setting.to_sym do
			return false if self.permissions.nil?
			self.permissions & SETTINGS[setting] > 0
		end
		
		define_method setting_setter do |value|
			if [true, 1, '1', 'true'].include?(value)
				self.permissions |= SETTINGS[setting]
			else
				self.permissions &= ~SETTINGS[setting]
			end
		end
	end
	
end


Signage::Application.config.advanced_auth.ug_mixin = proc do
	include AcaSignageSettings
end



Signage::Application.config.advanced_auth.invite_mixin = proc do
	
	include AcaSignageSettings
	
end



#
# For performing a redirect where login is successful.
#
Signage::Application.config.advanced_auth.redirection = proc { redirect_to medias_path }
Signage::Application.config.advanced_auth.login_title = "ACA Signage"
Signage::Application.config.advanced_auth.invite_title = "Signage Invite"

