class ApplicationController < ActionController::Base
	protect_from_forgery
	layout 'application'
	
	
	before_filter :authenticate, :except => [:present]
	before_filter :sidebar_information, :except => [:update_runtime, :update_move, :create, :update, :destroy, :present, :row, :publish, :preview, :move, :copy, :order, :recover, :error_retry]
	before_filter :set_locale
	
	
	helper_method :current_group
	helper_method :current_parent
	helper_method :current_permissions
	
	
	
	def default_url_options
		{
			:locale => I18n.locale
		}
	end
	
	
	
	#
	# Forbidden header used when users try to access data they should not
	#
	rescue_from SecurityTransgression, :with => lambda { head(:forbidden) }
	
	
	protected
	
	
	#
	# Defines the load limit for each ajax pagination request
	#	Must match the limit variable var pageLength in application.js
	# => TODO:: in the next version the javascript won't have to know this constant
	#
	PAGE_SIZE = 50
	def apply_pagination(search, params, default_order = nil)
		@item_list_length = search.count
		
		if request.xhr?
			search = search.limit(PAGE_SIZE)
			search = search.offset(params[:offset].to_i) if !params[:offset].nil?
			if !params[:order_desc].nil?
				search = search.order("#{params[:order_desc]} DESC")
			elsif !params[:order_asc].nil?
				search = search.order("#{params[:order_asc]} ASC")
			elsif !default_order.nil?
				search = search.order(default_order)
			end
		end
		
		return search
	end
	
	
	#
	# Used in Authsources, users, group_displays and convertors controllers
	#	Confirms user is a system admin
	#
	def check_sysadmin
		raise SecurityTransgression unless current_user.system_admin
	end
	
	def check_groupadmin
		raise SecurityTransgression unless current_user.system_admin || current_permissions.admin?
	end
	
	def check_publisher
		raise SecurityTransgression unless current_user.system_admin || current_permissions.publisher?
	end
	
	def authenticate
		if current_user.nil?
			redirect_to root_path
		end
	end
	
	#
	# Lazy load user information
	#	
	def current_group
		return @current_group unless @current_group.nil?
		
		if session[:group].present?
			@current_group = Group.find(session[:group])
		else
			@current_group = current_user.groups.first
			
			raise SecurityTransgression if @current_group.nil?

			session[:group] = @current_group.id
			session[:parent] = @current_group.id if session[:parent].nil?
			@current_group
		end
	end
	
	def current_parent
		return @current_parent unless @current_parent.nil?
		current_group
		@current_parent = Group.find(session[:parent])
	end
	
	def current_permissions
		@current_permissions ||= UserGroup.where(:user_id => session[:user], :group_id => current_parent.id).first
	end
	
	
	def set_locale
		# if params[:locale] is nil then I18n.default_locale will be used
		I18n.locale = params[:locale]
	end
	
	
	#
	# Layout information should only be downloaded when required (Layout rendering)
	#  TODO:: We need to move away from this
	#
	def sidebar_information
		return if request.xhr? || !request.format.html?
		
		@groups = current_group.display_groups
		@playlists = current_group.playlists.where('display_group_id IS NULL')
	end
	
	
	#
	# Our common responses for dealing with ajax updates
	#
	def minimal_response(item)
		if item.errors.empty?
			render :nothing => true
		else
			render 	:json => item.errors, :status => :unprocessable_entity
		end
	end
	
	def common_response(item)
		if item.errors.empty?
			render :json => item
		else
			render 	:json => item.errors, :status => :unprocessable_entity
		end
	end
	
	
	#
	# TODO:: temporary as we move towards the new interface
	#
	def media_as_json(media)
		@media_json = media.to_json({
			:include => {
				:formats => {
					:include => {
						:accepts_file => {:only => :mime}
					}
					#:only => :id
				},
				:plugin => {
					:only => [:can_play_to_end, :requires_data, :file_path]
				}
			}
		})
	end
	
end
