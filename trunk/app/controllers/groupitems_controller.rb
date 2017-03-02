class GroupitemsController < ApplicationController
	respond_to :xml, :json, :js
	respond_to :html, :only => :preview
	
	
	before_filter :check_publisher, :except => :show
	
	
	def show
		@display = DisplayGrouping.find(params[:id]).display
		current_group
		respond_with(@display) do |format|
			format.js { render 'displays/show', :layout => false }
		end
	end

	
	#
	# Assumes we are coming from the display URL if html request
	#
	def create
		display_ids = params[:displays]
		group_id =  params[:group_id]
		
		DisplayGrouping.transaction do
			display_ids.each do |display_id|
				if !DisplayGrouping.where('display_id = ? AND display_group_id = ?', display_id, group_id).exists?
					groupitem = DisplayGrouping.new(:display_id => display_id, :display_group_id => group_id)
					groupitem.save!
				end
			end
		end
		
		respond_with(@nothing) do |format|
			format.js { render :nothing => true, :layout => false }
		end
	end
	
	
	#
	# Copy screens from one group to another
	#
	def copy
		groupitems = DisplayGrouping.find(params[:items])
		group = params[:group]
		
		DisplayGrouping.transaction do
			groupitems.each do |item|
				if !DisplayGrouping.where('display_id = ? AND display_group_id = ?', item.display_id, group).exists?
					DisplayGrouping.create(item.attributes.merge({:display_group_id => group}))
				end
			end
		end
		
		respond_with(groupitems) do |format|
			format.js { render :nothing => true, :layout => false }
		end
	end
	
	
	#
	# Move screens from one group to another
	#
	def move
		groupitems = DisplayGrouping.find(params[:items])
		group = params[:group]
		old_group = groupitems[0].display_group_id
		
		DisplayGrouping.transaction do
			groupitems.each do |item|
				if !DisplayGrouping.where('display_id = ? AND display_group_id = ?', item.display_id, group).exists?
					item.display_group_id = group
					item.save!
				else
					item.destroy
					raise "Move Failed" unless item.destroyed?
				end
			end
		end
		
		respond_with(groupitems) do |format|
			format.js { render :nothing => true, :layout => false }
		end
	end
	
	
	#
	# Destroy playitems and redirect to playlist if HTML request
	#
	def destroy
		groupitems = DisplayGrouping.where('id in (?)', params[:items]).destroy_all
		
		respond_with(groupitems) do |format|
			format.js { render :nothing => true, :layout => false }
		end
	end

end
