module ApplicationHelper

	def mark_required(object, attribute)
		"*" if object.class.validators_on(attribute).map(&:class).include? ActiveModel::Validations::PresenceValidator  
	end
	
	
	def published?(playlist)
		return "publish show" if playlist.publish_pending?
		return "publish"
	end

end
