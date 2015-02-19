#!/usr/bin/env ruby

require 'elasticsearch'
require 'json'

class ESStats
  METRIC_GROUPS = ['nodes_stats', 'nodes_info', 'health']
  attr_reader :es_read_timeout, :cache_timeout, :metrics, :cache_file

  def initialize
    @es_read_timeout = 10
    @metrics       = ['jvm', 'os' ,'process']
    @cache_file    = '/tmp/eszabbix_stats.cache'
    @cache_timeout = 60
    @node_id       = nil
    @statistics    = nil
  end

  METRIC_GROUPS.each do |meth|
    define_method(meth) do
      read_statistics
      statistics["#{meth}"]
    end
  end

  # retrieve node_id from nodes_info, since nodes_info contains data only for local node
  def node_id
    @node_id ||= begin
      read_statistics
      statistics['nodes_info']['nodes'].keys.first
    end
  end

  # return client with preconfigured timeout
  def client
    @client ||= begin
      c = Elasticsearch::Client.new
      c.transport.get_connection.connection.options.open_timeout = es_read_timeout
      c.transport.get_connection.connection.options.timeout      = es_read_timeout
      c
    end
  end

  private

  attr_reader :statistics

  def read_statistics
    @statistics ||= begin
      all = {}
      mtime = File.mtime(cache_file) rescue (Time.now - cache_timeout)

      # load statistics from elasticsearch
      if Time.now - mtime > cache_timeout
        # Load local nodes info for all specified metrics
        info_opts = @metrics.inject({}) {|h, m| h[m.to_sym] = true; h}
        node_info = client.nodes.info(info_opts.merge({node_id: '_local'}))
        @node_id ||= node_info['nodes'].keys.first
        all['nodes_info'] = node_info
        all['health'] = client.cluster.health

        # Read indices metrics cluster-wide
        all['nodes_stats'] = client.nodes.stats metric: 'indices'

        # Separately for each metric load node local stats, should work on both 0.90, 1.x
        @metrics.inject(all['nodes_stats']) do |hash, m|
          data = client.nodes.stats({node_id: '_local', metric: m})
          hash['nodes'][node_id].merge!(data['nodes'][node_id])
          hash
        end

        File.open(cache_file, 'w') {|f| f.write(JSON.pretty_generate(all))}
        all
      else
        # from cache
        JSON.parse(IO.read(cache_file))
      end
    end
  end
end

class ESZabbix
  attr_reader :es, :metric_group, :metric_path, :cluster

  def initialize
    @es = ESStats.new
    @cluster = false
  end

  def metric(args)
    parse_args(args)
    if metric_group == 'service'
      zbx_fail "Unknown path #{metric_path}. Supports only service ping." if metric_path != 'ping'
      begin
        es.client.ping ? 1 : 0
      rescue TimeoutError
        0
      end
    elsif ESStats::METRIC_GROUPS.include? metric_group
      if !metric_path.start_with?('indices') && cluster
        zbx_fail "Aggregation is only available for indices metrics. Use cluster: prefix"
      elsif cluster
        es.nodes_stats['nodes'].keys.inject(0) do |s, id|
          s = s + read_metric_from(es.nodes_stats['nodes'][id])
        end
      else
        metrics = es.send(metric_group.to_sym)
        if metric_group == 'health' && metric_path == 'status'
          # Report status as green in case of failure, the item should be
          # aggregated over a cluster to provide cluster status.
          ['green','yellow','red'].find_index {|s| metrics['status'] == s} rescue 0
        elsif metric_group == 'health'
          read_metric_from(metrics)
        else
          read_metric_from(metrics['nodes'][es.node_id])
        end
      end
    else
      zbx_fail "Unknown metric group #{metric_group}"
    end
  rescue SystemExit
    raise
  end

  private

  def read_metric_from(hash)
    metric_path.split('.').inject(hash) {|h, i| h[i]} or zbx_fail "Could not read path #{metric_path} for #{metric_group}"
  rescue
    zbx_fail "Could not read path #{metric_path} for #{metric_group}"
  end

  # parse and check arguments
  def parse_args(args)
    zbx_fail 'You must provide two arguments like "nodes_stats indices.docs.count"' if args.size < 2
    @metric_group, @metric_path = args
    list = @metric_path.split(':')
    @metric_path = list.last
    @cluster = true if list.size > 1 && list.first == 'cluster'
  end

  # zabbix fail with unsupported item message
  def zbx_fail(msg=nil)
    puts "Error: #{msg}" if not msg.nil?
    puts "ZBX_NOTSUPPORTED"
    exit(2)
  end
end

stats = ESZabbix.new
puts stats.metric(ARGV)
