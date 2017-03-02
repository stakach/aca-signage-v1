class SubGroupsController < ApplicationController
	
	
	respond_to :json, :js
	respond_to :html, :only => :index
	
	
	before_filter :check_groupmanager
	
	
	def index
		@subgroups = Group.sub_search(current_group, params[:search], true)
		@subgroups = apply_pagination(@subgroups, params)
		
		respond_with(@groups)
	end
	
	
	def show
		@subgroup = Group.find(params[:id])
		respond_with(@subgroup)
	end
	
	def new
		@subgroup = Group.new
		respond_with(@subgroup)
	end
	
	def create
		@subgroup = Group.new(params[:group])
		
		Group.transaction do
			@subgroup.save
			current_group.add_child @subgroup
		end
		
		respond_with(@subgroup)
	end
	
	def edit
		@subgroup = Group.find(params[:id])
		respond_with(@subgroup)
	end
	
	def update
		@subgroup = current_group.children.where(:id => params[:id]).first	# prevent abuse
		
		@saved = @subgroup.update_attributes(params[:group])
		respond_with(@subgroup)
	end
	
	def destroy
		current_group.children.where('id IN (?)', params[:sub_groups]).destroy_all
		render :nothing => true, :layout => false
	end
	
	
	protected
	
	
	def check_groupmanager
		raise SecurityTransgression unless current_user.system_admin || current_permissions.group_manager? || current_permissions.domain_manager?
	end
	
	
end
