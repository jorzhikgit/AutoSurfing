#!/usr/bin/ruby

require 'uri'
require 'webrick'
require 'rubygems'
require 'em-websocket'

PORT=8088
APIPORT=8089

connections = []
url = "http://yahoo.co.jp"

Thread.new do
	while true
		sleep 60
		puts "Current users: #{connections.length}"
	end
end

Thread.new do
	srv = WEBrick::HTTPServer.new({:BindAddress => '0.0.0.0', :Port => APIPORT})
	srv.mount_proc("/") do |req, res|
		res.body = "use /redirect, /current or /users"
	end
	srv.mount_proc("/redirect") do |req, res|
		curl = url.gsub("\"", "&quot;")
		curl = curl.gsub("<", "&lt;")
		curl = curl.gsub(">", "&gt;")
		res.body = "<html><body><a href=\"#{curl}\">#{curl}</a></body></html>"
		res["location"] = url
		res.status = 302
	end
	srv.mount_proc("/current") do |req, res|
		curl = url.gsub("\"", "&quot;")
		curl = curl.gsub("<", "&lt;")
		curl = curl.gsub(">", "&gt;")
		res.body = "<html><body><a href=\"#{curl}\">#{curl}</a></body></html>"
		res["Content-type"] = "text/html"
	end
	srv.mount_proc("/users") do |req, res|
		res.body = connections.length.to_s
	end
	srv.start
end

EventMachine::WebSocket.start(:host=>"0.0.0.0", :port=>PORT) do |ws|
	ws.onopen do
		puts "join"
		connections.push(ws)
		ws.send "u:#{url}"
		connections.each do |c| c.send "c:#{connections.length}" end
	end
	ws.onmessage do |data|
		cmd = data.split(":", 2)
		case cmd[0]
			when "u"
				if cmd[1] =~ /^https?:\/\/.*/
					url = cmd[1]
					puts "changed url: #{url}"
					connections.each do |c| c.send "u:#{url}" end
				else
					puts "invalid url: #{cmd[1]}"
				end
			else
				puts "invalid command receive"
		end
	end
	ws.onclose do
		puts "close"
		connections.delete_if do |c| c == ws end
		connections.each do |c| c.send "c:#{connections.length}" end
	end
end

