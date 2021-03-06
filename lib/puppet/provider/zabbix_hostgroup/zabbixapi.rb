require 'rubygems'
require 'zabbixapi'
require 'pp'

Puppet::Type.type(:zabbix_hostgroup).provide(:zabbixapi) do

  confine :kernel => 'Linux'
  defaultfor :kernel => 'Linux'

  mk_resource_methods

  def self.prepare_zabbix_connection(resource)
    $zabbix_api ||= ZabbixApi.connect( :url => resource[:api_url], :user => resource[:api_user], :password => resource[:api_password] )
  end

  def self.instances
    zabbix_hostgroups = []
    hostgroups = $zabbix_api.hostgroups.get(:id => 0)
    hostgroups.each do |hostgroup|
      zabbix_hostgroups << new(:name => hostgroup['name'], :internal => hostgroup['internal'], :groupid => hostgroup['groupid'], :flags => hostgroup['flags'], :ensure => :present)
    end
    return zabbix_hostgroups
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      $zabbix_api || self.prepare_zabbix_connection(resource)
      if found = instances.find { |h| h.name == name }
        result = { :ensure => :present }
        result[:name] = found.name
        result[:groupid] = found.groupid
        result[:internal] = found.internal
        result[:flags] = found.flags
        resource.provider = new(result)
      else
        resource.provider = new(:ensure => :absent)
      end
    end
  end
  
  def api
    $zabbix_api
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    api.hostgroups.create(:name => @resource[:name])
    @property_hash[:ensure] = :present
  end

  def destroy
    api.hostgroups.delete(groupid)
    @property_hash.clear
  end

end