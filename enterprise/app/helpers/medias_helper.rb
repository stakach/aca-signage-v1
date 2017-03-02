module MediasHelper

	def is_transcoding(media)
		state = media.workflow_state.to_sym
		return ' transerror' if [:error, :invalid].include? state
		return ' transcoding' unless state == :ready
		return ''
	end
	
	def in_playlists(media)
		text = ""
		playlists = media.playlists.uniq
		
		
		if playlists.length == 0
			text += "<p>#{t(:media_not_in_playlist)}</p>"
		else
			text += "<p>#{t(:media_is_allocated_to)} " + playlists.length.to_s + " #{t(:playlists)}</p>"

			text += "<ul class='circle'>"
			playlists.each do |list|
				text += "<li>" + link_to(list.name, playlist_path(list.id)) + "</li>"  
			end
			text += "</ul>"
		end
		
		return text.html_safe
	end
		
end
