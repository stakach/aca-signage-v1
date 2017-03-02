require 'rubygems'
require 'net/ldap'

def get_attr(entry, attr_name)
	if attr_name != "" && attr_name != nil
		entry[attr_name].is_a?(Array) ? entry[attr_name].first : entry[attr_name]
	end
end

def get_user_attributes_from_ldap_entry(entry)
	return {:dn => entry.dn,
	:firstname => get_attr(entry, 'givenName'),
	:lastname => get_attr(entry, 'sN'),
	:mail => get_attr(entry, 'mail')}
end

def search_attributes
	['dn', 'givenName', 'sN', 'mail', 'memberOf']
end

ldap = Net::LDAP.new :host => "192.168.23.254",
     :port => 389,
     :auth => {
           :method => :simple,
           :username => "ADVANCEDCONTROL\\stakach",
           :password => "31J09st2"
     }

login_filter = Net::LDAP::Filter.eq( 'sAMAccountName', 'stakach' ) 
object_filter = Net::LDAP::Filter.eq( "objectClass", "*" ) 
treebase = "CN=Users,DC=advancedcontrol,DC=com,DC=au"
attrs = {}
ldap.bind
ldap.search( :base => treebase,
	:filter => object_filter & login_filter, 
	:attributes=> search_attributes) do |entry|
	
	p 'here'
	attrs = get_user_attributes_from_ldap_entry(entry)
	attrs.merge!(:member_of => entry['memberOf'].map {|e| /CN=([^,]+?)[,$]/i.match(e).captures.first })
			
	p "DN found: #{attrs[:dn]}"
end

p attrs.inspect