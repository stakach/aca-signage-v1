class GroupsController < ApplicationController
	respond_to :xml, :json, :js
	respond_to :html, :only => [:show, :destroy]
	
	
	include EnlightenObservers
	observer :audit_observer
	before_filter :user_check, :only => [:show, :edit, :update, :destroy, :footer]
	
	
	before_filter :check_publisher, :except => [:show, :footer, :new]
	
	
	
	def show
		#@group = DisplayGroup.find(params[:id])
		@groupdisplays = @group.search(params[:search])
		@groupdisplays = apply_pagination(@groupdisplays, params, 'displays.created_at DESC')
		respond_with(@group)
	end
	
	def new
		@group = DisplayGroup.new
		
		respond_with(@group)
	end
	
	def create
		@group = DisplayGroup.new(params[:display_group].merge({:group_id => current_group.id}))
		
		@group.save
		
		respond_with(@group)
	end
	
	def footer
		#@group = DisplayGroup.find(params[:id])
		respond_with(@group)
	end
	
	def edit
		#@group = DisplayGroup.find(params[:id])
		respond_with(@group)
	end
	
	def update
		#@group = DisplayGroup.find(params[:id])
		@saved = @group.update_attributes(params[:display_group])
		@groups = true	# allows for selection
		respond_with(@group)
	end
	
	def destroy
		#@group = DisplayGroup.find(params[:id])
		@group.destroy
		
		flash[:notice] = "#{t(:groups_deleted)}." if @group.destroyed?
		respond_with(@group) do |format|
			format.html { redirect_to medias_path }
		end
	end
	
	
	protected
	
	
	def user_check
		@group = DisplayGroup.find(params[:id])
		raise SecurityTransgression unless @group.group_id == current_group.id
	end
end
