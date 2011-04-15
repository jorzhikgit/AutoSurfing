#!/usr/bin/ruby

require 'uri'
require 'rubygems'
require 'em-websocket'

PORT=8088

connections = []
url = "http://yahoo.co.jp"

Thread.new do
	while true
		sleep 60
		puts "Current users: #{connections.length}"
	end
end

EventMachine::WebSocket.start(:host=>"0.0.0.0", :port=>PORT) do |ws|
	ws.onopen do
		puts "join"
		connections.push(ws)
		ws.send "u:#{url}"
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
	end
end

