#!/usr/local/bin/ruby

require 'rubygems'
require 'bundler/setup'
require 'cgi'
require 'cgi_exception'
require 'pp'
require 'digest/sha2'
require 'sqlite3'



cgi = CGI.new


print "Content-Type: text/html\n\n"

# bail out early if not authed, this shouldn't be possible, but just in case
unless ENV.has_key?("REMOTE_USER") || ENV["REMOTE_USER"] == ""
	print "You have not authenticated with CAS.<br />"
	exit
end


username = ENV["REMOTE_USER"]
#username.sub!("@.*$","")


if cgi.has_key?('genauth')
	db = SQLite3::Database.new("/usr/local/inspircd/conf/auth.sqlite3")
	if db.nil? 
		print "Cannot open sqlite file. Please report this\n";
	end
	password = (('a'..'z').to_a + ('0'..'9').to_a).shuffle[0,16].join
	hash = Digest::SHA2.hexdigest(password)

     	existing= db.get_first_row("select username from auth where username=='#{username}'")
	

	if existing.nil?
		begin
			db.execute("insert into auth values ('#{username}', '#{hash}')")
		rescue SQLite3::ReadOnlyException
			raise "The db was read only"
		#rescue	Exception => e
			#raise "Something else bad happened: #{e}"
		end
		print "There was a problem updating the database" unless db.errcode == 0
	else
		begin
			db.execute("update auth set password='#{hash}' where username=='#{username}'")
		rescue SQLite3::ReadOnlyException
			raise "The db was read only"
		#rescue	Exception => e
			#raise "Something else bad happened: #{e}"
		end
		print "There was a problem updating the database" unless db.errcode == 0
	end


	print "Your new password is: #{password}<br>"
else
	print "Hello #{username}.<br/>  Click to generate a new IRC auth password. Your old password will no longer work. "
	print "[<a href='ircauth.rb?genauth'>Generate new password</a>]"
end
