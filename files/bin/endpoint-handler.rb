#!/usr/bin/ruby

require "rubygems"
require "json"

def usage
	puts "endpoint-handler.rb [url] [route] [name]"
	puts " - where [url] like http://localhost:8080/management/application/submissionSummaries2"
	puts " - where [route] like summary?temporary-migration-visas?products"
	puts " - where [name] like pbs-dependant-child\n"
	puts " - note that if name is not an exact match, it will be treated as a regex"
	puts "   such that specifying 'pbs-' will match all JSON objects under path that"
	puts "   contain the text 'pbs-' and this script will then return a sum of their values"
end

if(ARGV.length < 3)
	$stderr.puts "Must specify three parameters!"
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
		if(target.has_key?(x))
	                target = target[x]
		else
			puts 0
			exit 0
		end
	}
	if(target.has_key?(theName))
		puts target[theName]
	else
		# since there isn't a match, presume this is a regex
		displaySumLike(target,theName)
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
