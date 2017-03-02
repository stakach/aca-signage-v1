module SubGroupsHelper
	
	def stats(group)
		text = "<b>Group Statistics</b><br /><br />There are #{group.user_groups.count} user(s)<br />There are #{group.group_displays.count} display(s)"
		
		return text.html_safe
	end
	
end
