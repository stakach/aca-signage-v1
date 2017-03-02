# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


files = AcceptsFile.create([

	# - Video
	{
		:ext => '.webm',
		:mime => 'video/webm',
		:enabled => true
	},
	{
		:ext => '.mp4',
		:mime => 'video/mp4',
		:enabled => true
	},
	
	# - Images:
	{
		:ext => '.png',
		:mime => 'image/png',
		:enabled => true
	},
	{
		:ext => '.jpg .jpeg',
		:mime => 'image/jpeg',
		:enabled => true
	},
	{
		:ext => '.gif',
		:mime => 'image/gif',
		:enabled => true
	},
	
	# - Audio:
	{
		:ext => '.m4a .aac',
		:mime => 'audio/mp4',
		:enabled => true
	},
	{
		:ext => '.ogg .oga',
		:mime => 'audio/vorbis',
		:enabled => true
	}
])

#
FileConversion.create(
	:accepts_file_id => nil,
	:applies_to => ".pptx .ppt .odp",
	:command => '["#{output}.wmv", "pptvideo #{input} #{output}.wmv"]',
	:description => "PowerPoint to Video",
	:enabled => true,
	:ordinal => 0
)

FileConversion.create(
	:accepts_file_id => files[1].id,
	:applies_to => ".avi .mpg .mov .wmv .mpeg .webm .ogv .ogg .m4v .mp4",
	:command => "[\"-vcodec libx264 -level 41 -crf 20 -bufsize 20000k -maxrate 25000k -g 250 -r 20 -coder 1 -flags +loop -cmp +chroma -partitions +parti8x8+parti4x4+partp8x8+partb8x8 -me_method umh -subq 7 -me_range 16 -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -b_strategy 1 -qcomp 0.6 -qmin 10 -qmax 51 -qdiff 4 -bf 3 -refs 3 -trellis 1\", \"-acodec aac -strict experimental -ar 44100 -ab 96k\"]",
	:description => "Video to H264",
	:enabled => true,
	:ordinal => 1
)

FileConversion.create(
	:accepts_file_id => files[0].id,
	:applies_to => ".avi .mpg .mov .wmv .mpeg .webm .ogv .ogg .m4v .mp4",
	:command => "[\"-vcodec libvpx -qmin 10 -qmax 42 -maxrate 25000k -bufsize 1000k -threads 2\",\"-acodec libvorbis -ab 128k\"]",
	:description => "Video to Webm",
	:enabled => true,
	:ordinal => 2
)

FileConversion.create(
	:accepts_file_id => files[2].id,
	:applies_to => ".bmp .psd .tiff .tif .pict",
	:command => '',	# No command modifiers is correct
	:description => "Image to PNG",
	:enabled => true,
	:ordinal => 3
)

FileConversion.create(
	:accepts_file_id => nil,
	:applies_to => ".pdf",
	:command => '["#{output}.png", "convert -density 164x164 -background white -flatten #{input}[0] #{output}.png"]',
	:description => "PDF to PNG",
	:enabled => true,
	:ordinal => 4
)

FileConversion.create(
	:accepts_file_id => files[5].id,
	:applies_to => ".m4a .aac .ogg .oga .mp3 .wav",
	:command => '-acodec aac -strict experimental -ar 44100 -ab 96k',
	:description => "Audio to AAC",
	:enabled => true,
	:ordinal => 5
)

FileConversion.create(
	:accepts_file_id => files[6].id,
	:applies_to => ".m4a .aac .ogg .oga .mp3 .wav",
	:command => '-acodec libvorbis -ab 128k -strict experimental',
	:description => "Audio to OGG",
	:enabled => true,
	:ordinal => 6
)


Plugin.create(
	:name => 'YouTube',
	:file_path => '/plugins/youtube/youtube.html',
	:help => 'Enter the video id*',
	:can_play_to_end => true,
	:requires_data => true
)


Plugin.create(
	:name => 'Flickr',
	:file_path => '/plugins/flickr/flickr.html',
	:help => 'Enter the photo id*',
	:can_play_to_end => false,
	:requires_data => true
)


Plugin.create(
	:name => 'Vimeo',
	:file_path => '/plugins/vimeo/vimeo.html',
	:help => 'Enter the video id*',
	:can_play_to_end => true,
	:requires_data => true
)

Plugin.create(
	:name => 'Trusted Web Page',
	:file_path => '/plugins/trusted_url/trusted_url.html',
	:help => 'Enter the site URL*',
	:can_play_to_end => false,
	:requires_data => true
)


group = Group.create(
	:identifier => 'ACA',
	:description => 'ACA',
	:timezone => 'Sydney'
)


invite = Invite.new(
	:group_id => group.id,
	:email => 'steve@webcontrol.me'
)
invite.permissions = 255
invite.save




