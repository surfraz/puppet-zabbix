require 'rubygems'
require 'zabbixapi'
require 'pp'

Puppet::Type.type(:zabbix_usergroup).provide(:zabbixapi) do

  confine :kernel => 'Linux'
  defaultfor :kernel => 'Linux'

  mk_resource_methods

  def self.prepare_zabbix_connection(resource)
    $zabbix_api ||= ZabbixApi.connect( :url => resource[:api_url], :user => resource[:api_user], :password => resource[:api_password] )
  end

  def self.instances
    zabbix_usergroups = []
    usergroups = $zabbix_api.usergroups.get(:id => 0)
    usergroups.each do |usergroup|
      zabbix_usergroups << new(:name => usergroup['name'], :usergroupid => usergroup['usrgrpid'], :guiaccess => usergroup['gui_access'], :status => usergroup['users_status'], :debugmode => usergroup['debug_mode'], :ensure => :present)
    end
    return zabbix_usergroups
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      $zabbix_api || self.prepare_zabbix_connection(resource)
      if found = instances.find { |h| h.name == name }
        result = { :ensure => :present }
        result[:name] = found.name
        result[:usergroupid] = found.usergroupid
        result[:guiaccess] = found.guiaccess
        result[:status] = found.status
        result[:debugmode] = found.debugmode
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

  def grouppermissions
    read_rights = []
    write_rights = []

    # collect groupids and create API rights object items
    @resource[:initialreadaccess].each do |group|
      id = api.hostgroups.get(:name => group).first['groupid']
      read_rights << {:permission => 2, :id => id }
    end
    @resource[:initialwriteaccess].each do |group|
      id = api.hostgroups.get(:name => group).first['groupid']
      write_rights << {:permission => 3, :id => id }
    end

    return read_rights + write_rights # array of hash items
  end

  def create
    query_params = {
      :name => @resource[:name],
      :guiaccess => @resource[:guiaccess],
      :users_status => @resource[:status],
      :debug_mode => @resource[:debugmode],
    }

    query_params[:rights] = grouppermissions if grouppermissions

    api.query(:method => 'usergroup.create',
              :params => query_params
    )
    @property_hash[:ensure] = :present
  end

  def destroy
    api.usergroups.delete(usergroupid)
    @property_hash.clear
  end

  def guiaccess=(value)
    api.query(:method => 'usergroup.update',
              :params => {
                  :usrgrpid => @property_hash[:usergroupid],
                  :gui_access => value
              })
    @property_hash[:guiaccess] = value
  end

  def status=(value)
    api.query(:method => 'usergroup.update',
              :params => {
                  :usrgrpid => @property_hash[:usergroupid],
                  :users_status => value
              })
    @property_hash[:status] = value
  end

  def debugmode=(value)
    api.query(:method => 'usergroup.update',
              :params => {
                  :usrgrpid => @property_hash[:usergroupid],
                  :debug_mode => value
              })
    @property_hash[:debugmode] = value
  end
end