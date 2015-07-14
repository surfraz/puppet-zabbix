#!/usr/bin/ruby

require "rubygems"
require "json"

def usage
	puts "endpoint-handler.rb [url] [route] [name] [value tag name]"
	puts " - where [url] like http://localhost:8080/management/application/submissionSummaries2"
	puts " - where [route] like summary?temporary-migration-visas?products"
	puts " - where [name] like pbs-dependant-child\n"
	puts " - note that if name is not an exact match, it will be treated as a regex"
	puts "   such that specifying 'pbs-' will match all JSON objects under path that"
	puts "   contain the text 'pbs-' and this script will then return a sum of their values"
	puts
	puts " - specifying a route or a name that contains an '=' sign will cause this to be "
	puts "   interpreted as a key value pair identifying a section of json"
	puts "   - so that $0 [url] germany?city=munich population would be appropriate where"
	puts "     germany is searched as an array, and the path where city = munich will be"
	puts "     followed (this functionality does not extend to summing)"
	puts "   - if the name is specified with an '=' sign, such that name=bob, or city=munich"
	puts "     is followed, then by default the script expects to look for a 'value=x' but"
	puts "     this can be overridden with a different value name, such as count or num by"
	puts "     specifying this as a 4th parameter to the script"
	puts
	puts " - where route is empty, specify an explicit empty string \"\""
	puts
end

if(ARGV.length < 3)
	$stderr.puts "Must specify three or more parameters!"
	usage
	exit 1
end

url=ARGV[0]
route=ARGV[1]
name=ARGV[2]

fileExpiry = 60 # time after which to re-read file (in seconds)

workDir="/var/lib/zabbix/endpoint-handler"

if(!File.directory?(workDir))
	Dir.mkdir(workDir)
end
Dir.chdir(workDir)

file = url.sub("http://","")
file = file.gsub(/[\/:]/,".")
file = file + ".cache"

def displaySumLike(theHash,theRegex)
	theSum=0
	theRegex = Regexp.new(theRegex)
	theHash.keys.each{ |key|
		if(theRegex.match(key))
			theSum += theHash[key]
		end
	}
	puts(theSum)
end

def display(theFile,theRoute,theName)
	input = File.read(theFile)
        parsed = JSON.parse(input) # a hash

        routeArray=theRoute.split('?')
	target = parsed

	# walk through route to name
	routeArray.each{ |x|
		if(x != "") then
			spl = x.split('=')
			if(spl[1]) then
				#puts("it split")
				target.each do |bit|
					if(bit[spl[0]] == spl[1]) then
						target = bit
						break
					end
				end
			else
				if(target.has_key?(x))
			                target = target[x]
				else
					puts 0
					exit 0
				end
			end
		end
	}
	spl = theName.split('=')
	if(spl[1]) then
		target.each do |bit|
			if(bit[spl[0]] == spl[1]) then
				puts bit["value"]
				break
			end
		end
	else
		if(target.has_key?(theName))
			puts target[theName]
		else
			# since there isn't a match, presume this is a regex
			displaySumLike(target,theName)
		end
	end
end

def collect(theUrl,theFile)
	require "rest-client"
        begin
                response = RestClient.get(theUrl)
                if(response.code != 200)
                        $stderr.puts("Failed to get endpoint " + theUrl + "\nReturn code: " + response.code)
                        exit 1
                end
        rescue Errno::ECONNREFUSED
                $stderr.puts("Server refusing connection!")
                exit 1
	rescue RestClient::ResourceNotFound
		$stderr.puts("Server returned 404! "+ theUrl)
		exit 2
        end

        File.open(theFile, 'w') { |theFile| theFile.write(response.to_str) }
end





if(File.exists?(file))
	fileAge = (Time.now - File.stat(file).mtime).to_i
else
	fileAge = fileExpiry + 1
end
if(fileAge > fileExpiry)
	collect(url,file)
end
display(file,route,name)



exit 0
