class Format < ActiveRecord::Base
	belongs_to	:media
	belongs_to	:accepts_file
	
	
	after_destroy		:delete_file
	
	
	scope :target, proc {|target_id| where(:target_id => target_id)} 
	
	
	include Workflow
	workflow do
		state :converting do
			event :failure,			:transitions_to => :error
			event :complete,		:transitions_to => :ready
		end
		
		#
		# TODO:: on ready event check if there are any displays that need updating
		#
		state :ready do
		end
		
		state :error do
			event :retry,			:transitions_to => :converting
		end
		
		after_transition do |from, to, triggering_event, *event_args|
			if to.to_sym == :ready
				if media.formats.where('workflow_state <> ?', 'ready').count() == 0
					media.complete!
				end
			end
		end
	end
	
	
	def url
		file_path.sub('public', '')
	end
	
	
	protected
	
	
	#
	# This job will attempt to delete the file multiple times
	# => Runs at a time that ensures playlists are updated remotely
	#
	def delete_file
		Delayed::Job.enqueue DeleteFileJob.new(self.file_path), :queue => 'delete', :run_at => 5.minutes.from_now unless self.file_path == self.media.file_path
	end
	
	
	validates_presence_of :accepts_file, :media
end
