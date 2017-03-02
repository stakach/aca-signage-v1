class UsersController < ApplicationController
	respond_to :xml, :json, :js
	respond_to :html, :only => :index
	
	
	before_filter :check_groupadmin
	
	
	def index
		@users = User.search(current_group, params[:search])
		@users = apply_pagination(@users, params, 'users.created_at DESC')
		
		respond_with(@users)
	end
	
	def show
		@user = User.find(params[:id])
		@group = UserGroup.where('user_groups.user_id = ? AND user_groups.group_id = ?', @user.id, current_group.id).first
		respond_with(@user)
	end
	
	def new
		@invite = Invite.new
		respond_with(@invite)
	end
	
	def create
		@invite = Invite.new(params[:invite])
		
		@invite.group = current_group
		@invite.publisher = params[:invite][:publisher]
		@invite.admin = params[:invite][:admin]
		@invite.group_manager = 0
		@invite.domain_manager = 0
		@invite.group_manager = params[:invite][:group_manager] if current_permissions.group_manager || current_permissions.domain_manager
		@invite.domain_manager = params[:invite][:domain_manager] if current_permissions.domain_manager
		@invite.display_alerts = params[:invite][:display_alerts]
		
		@invite.save
		
		respond_with(@invite)
	end
	
	def edit
		@user = User.find(params[:id])
		@group = UserGroup.where('user_groups.user_id = ? AND user_groups.group_id = ?', @user.id, current_group.id).first
		respond_with(@user)
	end
	
	def update
		@group = UserGroup.where('user_groups.user_id = ? AND user_groups.group_id = ?', params[:id].to_i, current_group.id).first
		@group.publisher = params[:user_group].delete(:publisher)
		@group.admin = params[:user_group].delete(:admin)
		@group.group_manager = params[:user_group].delete(:group_manager)	if current_permissions.group_manager || current_permissions.domain_manager
		@group.domain_manager = params[:user_group].delete(:domain_manager) if current_permissions.domain_manager
		params[:user_group].delete(:group_manager)	# just to make sure
		params[:user_group].delete(:domain_manager)
		@group.display_alerts = params[:user_group].delete(:display_alerts)
		@saved = @group.update_attributes(params[:user_group])
		@user = @group.user
		respond_with(@group)
	end
	
	def destroy
		users = UserGroup.where('user_id in (?) AND group_id = ? AND (permissions & 12) <= ?', params[:users], current_group.id, current_permissions.permissions & 0b1100).destroy_all
		render :nothing => true, :layout => false
	end
end
