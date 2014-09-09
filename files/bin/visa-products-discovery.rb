#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'

# results will be built as a hash
results = {}
results['data'] = Array.new

# we will read the data from here
url = ARGV[0]

submissionSummaryRaw = %x{curl -q #{url} 2>/dev/null}

# JSON to ruby hash
submissionSummary = JSON.parse(submissionSummaryRaw)

submissionSummary['summary'].keys.each do |product|
  results['data'] << { '{#PRODUCT}' => product }
end

# let them eat JSON
puts JSON.pretty_generate(results)