class ConvertersController < ApplicationController
	respond_to :xml, :json, :js
	respond_to :html, :only => :index
	
	
	before_filter :check_sysadmin
	
	
	def index
		@converters = FileConversion.search(params[:search])
		@converters = apply_pagination(@converters, params, nil)
		respond_with(@converters)
	end
	
	def show
		@converter = FileConversion.find(params[:id])
		respond_with(@converter)
	end
	
	def new
		@converter = FileConversion.new
		respond_with(@converter)
	end
	
	def create
		@converter = FileConversion.new(params[:converter])
		
		@converter.save
		
		respond_with(@converter)
	end
	
	def edit
		@converter = FileConversion.find(params[:id])
		respond_with(@converter)
	end
	
	def update
		@converter = FileConversion.find(params[:id])
		
		@saved = @converter.update_attributes(params[:file_conversion])
		respond_with(@converter)
	end
	
	def order
		FileConversion.order_all(params[:converter])
		respond_with(nil) do |format|
			format.js { render :nothing => true, :layout => false }
		end
	end
	
	def destroy
		converters = FileConversion.where('id in (?)', params[:converters]).destroy_all
		
		respond_with(converters[0]) do |format|
			format.js { render :nothing => true, :layout => false }
		end
	end
end
