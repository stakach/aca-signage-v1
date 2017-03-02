class UgController < ApplicationController
	
	
	respond_to :xml, :json, :js
	respond_to :html, :only => :index
	
	
	before_filter :check_groupadmin, :except => :index
	
	
	def index
		@groups = Group.search(current_user, params[:search])
		@groups = apply_pagination(@groups, params)
		if params[:limit].present?
			limit = params[:limit].to_i
			@groups = @groups.limit(limit) unless limit > PAGE_SIZE
		end
		
		respond_with(@groups)
	end
	
	
	def subgroups
		@groups = Group.sub_search(current_parent, params[:search])
		@groups = apply_pagination(@groups, params)
		if params[:limit].present?
			limit = params[:limit].to_i
			@groups = @groups.limit(limit) unless limit > PAGE_SIZE
		end
		
		respond_with(@groups)
	end
	
	
	
	
	
end
