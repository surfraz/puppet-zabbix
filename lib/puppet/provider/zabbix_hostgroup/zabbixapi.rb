require 'rubygems'
require 'zabbixapi'
require 'pp'

Puppet::Type.type(:zabbix_hostgroup).provide(:zabbixapi) do

  confine :kernel => 'Linux'
  defaultfor :kernel => 'Linux'

  mk_resource_methods

  def self.instances
    # cannot return instances without creds :-(
  end

  def self.prefetch(resources)
    zabbix_hostgroups = []
    #get creds #FIXME
    first_resource = resources.first[1]
    zabbix_api = ZabbixApi.connect( :url => first_resource[:api_url], :user => first_resource[:api_user], :password => first_resource[:api_password] )
    hostgroups = zabbix_api.hostgroups.get(:id => 0)
    hostgroups.each do |hostgroup|
      zabbix_hostgroups << new(:name => hostgroup['name'], :internal => hostgroup['internal'], :groupid => hostgroup['groupid'], :flags => hostgroup['flags'], :ensure => :present)
    end

    Puppet.debug(puts(pp zabbix_hostgroups))
    Puppet.debug(puts(pp resources))
    resources.each do |name, instance|
      if found = zabbix_hostgroups.find { |x| x.name == name }
        result = { :ensure => :present, }
        result[:internal] = found.internal
        result[:flags] = found.flags
        result[:groupid] = found.groupid
        instance.provider = new(found, result)
      else
        instance.provider = new(nil, :ensure => :absent)
      end
      instance.provider.zabbixapi = zabbixapi
    end
  end

  def api
    @api ||= zabbix_api = ZabbixApi.connect( :url => @resource[:api_url], :user => @resource[:api_user], :password => @resource[:api_password] )
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    api.hostgroups.create(:name => @resource[:name])
  end

  def destroy
    api.hostgroups.delete(:id)
  end

  def internal
    @property_hash[:internal]
  end

  def internal=
    @property_hash[:internal]
  end

  def groupid
    @property_hash[:groupid]
  end

  def groupid=
    @property_hash[:groupid]
  end

  def flags
    @property_hash[:flags]
  end

  def flags=
    @property_hash[:flags]
  end

end