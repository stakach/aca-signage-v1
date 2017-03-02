desc "Start a delayed_job worker for processing video transcoding."
task :video_conversions => :environment do
	Delayed::Worker.new(:queues => ['video'], :quiet => false).start
end


desc "Start a delayed_job worker for processing audio transcoding."
task :audio_conversions => :environment do
	Delayed::Worker.new(:queues => ['audio'], :quiet => false).start
end


desc "Start a delayed_job worker for processing video transcoding."
task :av_conversions => :environment do
	Delayed::Worker.new(:queues => ['video', 'audio'], :quiet => false).start
end


desc "Start a delayed_job worker for processing fairly quick tasks."
task :other_tasks => :environment do
	Delayed::Worker.new(:queues => ['delete', 'clean', 'checking', 'image', 'mail'], :quiet => false).start
end


desc "Start a delayed_job worker for processing schedules and display online status."
task :process_schedules => :environment do
	Delayed::Worker.new(:queues => ['schedule', 'display'], :quiet => false).start
end


desc "An all tasks processor for dev."
task :all_tasks => :environment do
	Delayed::Worker.new(:queues => ['schedule', 'display', 'delete', 'clean', 'checking', 'image', 'audio', 'video', 'mail'], :quiet => false).start
end
