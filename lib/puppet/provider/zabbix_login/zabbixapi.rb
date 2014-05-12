require 'rubygems'
require 'zabbixapi'
require 'pp'

Puppet::Type.type(:zabbix_login).provide(:zabbixapi) do

  confine :kernel => 'Linux'
  defaultfor :kernel => 'Linux'

  mk_resource_methods

  def self.prepare_zabbix_connection(resource)
    begin
      $zabbix_api ||= ZabbixApi.connect( :url => resource[:api_url], :user => resource[:api_user], :password => resource[:api_password] )
    rescue
      $zabbix_api ||= ZabbixApi.connect( :url => resource[:api_url], :user => 'Admin', :password => 'zabbix' )
    end
  end

  def self.instances
    zabbix_users = []
    users = $zabbix_api.users.get(:id => 0)
    users.each do |user|
      zabbix_users << new(:name => user['alias'], :userid => user['userid'], :firstname => user['name'], :type => user['type'], :lastname => user['surname'], :ensure => :present)
    end
    return zabbix_users
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      self.prepare_zabbix_connection(resource)
      if found = instances.find { |h| h.name == name }
        result = { :ensure => :present }
        result[:name] = found.name
        result[:userid] = found.userid
        result[:firstname] = found.firstname
        result[:lastname] = found.lastname
        result[:type] = found.type
        resource.provider = new(result)
      else
        resource.provider = new(:ensure => :absent)
      end
    end
  end
  
  def api
    $zabbix_api ||= ZabbixApi.connect( :url => resource[:api_url], :user => resource[:api_user], :password => resource[:api_password] )
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def usergroups
    groups = []

    # collect groupids and create API rights object items
    @resource[:usergroups].each do |group|
      id = api.usergroups.get(:name => group).first['usrgrpid']
      groups << { :usrgrpid => id }
    end

    return groups # array of hash items
  end

  def create
    # generate a random password (not user accessible)
    if @resource[:password].empty?
      passwd = (0...60).map { ('a'..'z').to_a[rand(26)] }.join
    else
      passwd = @resource[:password] ||(0...60).map { ('a'..'z').to_a[rand(26)] }.join
    end


    # get usergroup ids
    group_ids = []
    @resource[:usergroups].each do |groupname|
      group_ids << api.query(:method => 'usergroup.get',
                             :params => {
                                 :search => {
                                     :name => groupname
                                 }
                             }).first['usrgrpid']
    end

    api.query(:method => 'user.create',
              :params => {
                  :alias => @resource[:name],
                  :passwd => passwd,
                  :name => @resource[:firstname],
                  :surname => @resource[:lastname],
                  :type => @resource[:type],
                  :usrgrps => group_ids
              }
    )
    @property_hash[:ensure] = :present
  end

  def destroy
    api.users.delete(userid)
    @property_hash.clear
  end

  def firstname=(value)
    pp @property_hash
    api.query(:method => 'user.update',
              :params => {
                :userid => @property_hash[:userid],
                :name => value
              })
    @property_hash[:userid] = value
  end

  def lastname=(value)
    api.query(:method => 'user.update',
              :params => {
                  :userid => @property_hash[:userid],
                  :surname => value
              })
    @property_hash[:lastname] = value
  end

  def type=(value)
    api.query(:method => 'user.update',
              :params => {
                  :userid => @property_hash[:userid],
                  :type => value
              })
    @property_hash[:type] = value
  end

  def usergroups
    groups = []

    id = api.query(:method => 'user.get',
                  :params => {
                      :search => { :alias => @resource[:name] }
                  }).first['userid']

    groupobjects = api.query(:method => 'usergroup.get',
              :params => {
                  :userids => id,
                  :output => 'extend'
              })

    groupobjects.each do |group|
      groups << group['name']
    end

    return groups
  end

  def usergroups=(value)
    usergroup_ids = []

    value.each do |group|
      id = api.query(:method => 'usergroup.get',
                          :params => {
                              :search => {
                                :name => group
                              }
                          }).first['usrgrpid']

      usergroup_ids << { :usrgrpid => id }
    end

    api.query(:method => 'user.update',
              :params => {
                  :userid => @property_hash[:userid],
                  :usrgrps => usergroup_ids
              })
  end

  def password
    if @resource[:password].empty?
      return ''
    else
      begin
        result = ZabbixApi.connect( :url => resource[:api_url], :user => @resource[:name], :password => @resource[:password] )
      rescue
        result = 'FAILED_AUTH'
      end
      return result
    end

  end

  def password=(value)
    api.query(:method => 'user.update',
              :params => {
                  :userid => @property_hash[:userid],
                  :passwd => @resource[:password]
              })
  end
end