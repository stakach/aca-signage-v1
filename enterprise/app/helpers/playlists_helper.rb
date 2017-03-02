module PlaylistsHelper


	def in_groups(playlist)
		text = ""
		thecount = playlist.display_groups.count
		
		if thecount == 0
			text += "<p>#{t(:playlist_not_scheduled)}</p>"
		else
			text += "<p>#{t(:playlist_displayed_in)} " + thecount.to_s + " #{t(:schedules)}</p>"

			text += "<ul class='circle'>"
			playlist.display_groups.each do |group|
				text += "<li>" + link_to(group.name, group_path(group.id)) + ": #{h(group.comment)}</li>"  
			end
			text += "</ul>"

		end
		
		return text.html_safe
	end


end
