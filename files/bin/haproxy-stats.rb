#! /usr/bin/env ruby
require 'csv'
require 'json'

haproxy_config = '/etc/haproxy/haproxy.cfg'
socket_file = ''

def get_socket_location(file)
  socket = ''
  File.open(file).readlines.each do |line|
    if line =~ /^\s+stats\s+socket\s+(\S+)$/
      socket = $1
    end
  end

  return socket
end

# should return a json doc in zabbix discovery format
#e.g. {"data":[{"{#PXNAME}":"dcj-admin","{#SVNAME}":"FRONTEND"},{"{#PXNAME}":"dcj-admin","{#SVNAME}":"dcj-admin-lb"},{"{#PXNAME}":"dcj-admin","{#SVNAME}":"BACKEND"},{"{#PXNAME}":"dcj-customer","{#SVNAME}":"FRONTEND"},{"{#PXNAME}":"dcj-customer","{#SVNAME}":"dcj-customer-lb"},{"{#PXNAME}":"dcj-customer","{#SVNAME}":"BACKEND"},{"{#PXNAME}":"stats","{#SVNAME}":"FRONTEND"},{"{#PXNAME}":"stats","{#SVNAME}":"BACKEND"}]}
def discover_haproxy_objects(stats)
  objects = {'data' => []}
  stats[1..-1].each do |item|
    next if item[0].nil?
    instance = {}
    objects['data'] <<
        {
            '{#PXNAME}' => item[0],
            '{#SVNAME}' => item[1],
        }
  end

  return objects.to_json
end

socket_file = get_socket_location(haproxy_config)
stats_output = %x(echo "show stat" | sudo nc -U #{socket_file})
stats = CSV.parse(stats_output)

def get_haproxy_statistic(stats, px, sv, item)
  index = stats[0].index(item)
  row = stats.select {|item| item[0] == px && item[1] == sv}
  return row[0][index]
end

case ARGV[0]
  when 'discovery'
    puts discover_haproxy_objects(stats)
  else
    if ARGV.length == 3
      puts get_haproxy_statistic(stats, ARGV[0], ARGV[1], ARGV[2])
    else
      raise 'No instructions provided, cannot perform an action'
    end
end