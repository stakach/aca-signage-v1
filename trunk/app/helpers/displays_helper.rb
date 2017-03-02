module DisplaysHelper
	
	def host
		request.protocol + request.host_with_port
	end

	#
	# How many users also have this display
	#
	def shared?(display, short = true)
		text = ""
		if display.group_displays.exists?
			text += "#{t(:display_shared_between)} #{display.group_displays.joins(:group).count} #{t(:users)}, "
		end
		thecount = display.display_groups.where('group_id = ?', current_group.id).count
		if thecount == 0
			text += t(:display_not_in_schedule)
		else
			if(short)
				text += "#{t(:in)} " + thecount.to_s + " #{t(:groups).downcase}"
			else
				text += "#{t(:in)} " + thecount.to_s + " #{t(:groups).downcase}<table><tr><th class='desc'>#{t(:group)}</th><th class='desc'>#{t(:playlist)}</th></tr>"
				if thecount > 0
					display.display_groups.where('group_id = ?', current_group.id).each do |group|
						text += "<tr><td>" + link_to(group.name, group_path(group.id)) + ": </td><td>"
						if group.playlist.nil?
							text += "#{t(:display_no_playlist)}</td></tr>"
						else
							text += "" + link_to(group.playlist.name, playlist_path(group.playlist_id)) + "</td></tr>"
						end
					end
				end
				text += "</table>"
			end
		end
		
		return text.html_safe
	end
	
	
	def display_uptime(display)
		if display.last_seen.nil?
			return " title='#{t(:display_no_use)}' class='black'".html_safe
		elsif display.last_seen > Time.now - 5.minutes
			return " title='#{t(:display_online)}' class='green'".html_safe
		elsif display.last_seen > Time.now - 20.minutes
			return " title='#{t(:display_unknown)}' class='orange'".html_safe
		else
			return " title='#{t(:display_offline)}' class='red'".html_safe
		end
	end
	
	
	
	def gen_display_link(display)
		if display.permalink.present?
			return ["/#{display.permalink}", "#{host}/#{display.permalink}.html"]
		else
			return ["/displays/#{display.id}/present","#{host}/displays/#{display.id}/present.html"]
		end
	end
	

end
