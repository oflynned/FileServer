require 'socket'
require 'uri'

#host definitions
host = 'localhost'
port = 2345

#directory definitions
WEB_ROOT = './public'

#mapping
DEFAULT_CONTENT_TYPE = 'application/octet-stream'
CONTENT_TYPE_MAPPING = {
	'html' => 'text/html',
	'txt' => 'text/plain',
	'png' => 'image/png',
	'jpg' => 'image/jpeg'
}

def content_type(path)
	#get extension by clipping
	ext = File.extname(path).split(".").last
	CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
end

#retrieve file from given path
def request_file(request)
	req_uri = request.split(" ")[1]
	path = URI.unescape(URI(req_uri).path)
	clean = []
	
	#split by '/' components
	parts = path.split("/")
	parts.each do |part|
		next if part.empty? || part == '.'
		#prevent path directory popping to root
		part == ".." ? clean.pop : clean << part
	end
	File.join(WEB_ROOT, *clean)
end

server = TCPServer.new(host, port)

loop do
	socket = server.accept
	request = socket.gets
	STDERR.puts request
	response = "retrieving file lol\n"
	
	#pathing
	path = request_file(request)
	
	#req html file
	path = File.join(path, 'index.html') if File.directory?(path)
	
	if File.exist?(path) && !File.directory?(path)
	#provide file
		File.open(path, "rb") do |file|
			socket.print 	"HTTP/1.1 200 OK\r\n" +
										"Content-Type: #{content_type(path)}\r\n" +
										"Content-Length: #{file.size}\r\n" +
										"Connection: close\r\n"
			
			socket.print "\r\n"
			#copy retrieved file from path to TCP socket
			IO.copy_stream(file, socket)
		end
	else
	#else not found - echo 404
		message = "File not found error 404\n"
		socket.print 	"HTTP/1.1 404 Not Found\r\n" +
										"Content-Type: text/plain\r\n" +
										"Content-Length: #{message.size}\r\n" +
										"Connection: close\r\n"
		socket.print "\r\n"
		socket.print message
	end
	socket.close
end

