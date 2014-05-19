#! /usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'json'
require 'net/http'
require 'lib/zabbix'

url = ARGV[0]
itemsfile = 'filters/' + ARGV[1]
itemprefix = ARGV[2]
host = %x(facter fqdn)

def flatten_hash(h, k = [])
  new_hash = {}
  h.each_pair do |key, val|
    if val.is_a?(Hash)
      new_hash.merge!(flatten_hash(val, k + [key]))
    else
      new_hash[k + [key]] = val
    end
  end
  new_hash
end

def get_metrics(url)
  resp = Net::HTTP.get_response(URI.parse(url))
  data = resp.body

  # we convert the returned JSON data to native Ruby
  # data structure - a hash
  result = JSON.parse(data)

  # if the hash has 'Error' as a key, we raise an error
  if result.has_key? 'Error'
    raise "web service error"
  end

  return result
end

def required_items(file)
  items = []

  File.open(file).readlines.each do |line|
    if line.strip =~ /^(\S+::.*)\s+(\S+)$/
      items << $1.split('::')
    end
  end

  return items
end

def sender_hash(items, metrics, itemprefix)
  sender_hash = {}
  items.each do |item|
    if metrics.has_key? item
      # key convention used in our templates
      itemkey = itemprefix + '--' + item.join('-').gsub(' ', '_')
      sender_hash[itemkey] = metrics[item].to_s
    end
  end
  return sender_hash
end

metrics_hash = get_metrics(url)
metrics = flatten_hash(metrics_hash)

zabbix = Zabbix::Sender.new

status = zabbix.to(host.strip) do
  sender_hash(required_items(itemsfile), metrics, itemprefix).each_pair do |key, value|
    send key, value
  end
end

puts status.inspect
