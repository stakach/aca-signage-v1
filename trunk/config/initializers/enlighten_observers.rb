#
# Based on http://scie.nti.st/2007/2/1/let-activerecord-observers-see-controller-context
#	MIT or X11 license
#

module EnlightenObservers
	def self.included(base)
		base.extend(ClassMethods)
	end
	
	module ClassMethods
		def observer(*observers)
			configuration = observers.last.is_a?(Hash) ? observers.pop : {}
			observers.each do |observer|
				observer_instance = Object.const_get(observer.to_s.classify).instance
				class <<observer_instance
					include Enlightenment
				end
				
				around_filter(observer_instance, :only => configuration[:only])
			end
		end
	end
	
	module Enlightenment
		def self.included(base)
			base.module_eval do
				attr_accessor :controller
			end
		end
		
		def before(controller)
			self.controller = controller
		end
		
		def after(controller)
			self.controller = nil # Clean up for GC
		end
	end
end
