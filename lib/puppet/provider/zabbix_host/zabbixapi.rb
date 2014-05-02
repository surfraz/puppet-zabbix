require 'rubygems'
require 'zabbixapi'
require 'pp'

Puppet::Type.type(:zabbix_host).provide(:zabbixapi) do

  confine :kernel => 'Linux'
  defaultfor :kernel => 'Linux'

  mk_resource_methods

  def self.prepare_zabbix_connection(resource)
    $zabbix_api ||= ZabbixApi.connect( :url => resource[:api_url], :user => resource[:api_user], :password => resource[:api_password] )
  end

  def self.instances
    zabbix_hosts = []
    hosts = $zabbix_api.hosts.get(:id => 0)
    hosts.each do |host|
      first_interface = $zabbix_api.query(:method => 'host.get',
                     :params => {
                         :selectInterfaces => 'extend',
                         :filter => {
                             'hostid' => [host['hostid']]
                         }
                     }).first['interfaces'].first

      zbx_groups = $zabbix_api.query(:method => 'hostgroup.get',
                                 :params =>
                                     {
                                         :output => 'extend',
                                         :hostids => [host['hostid']]
                                     }).collect{|g| g['name']}

      zbx_templates = $zabbix_api.query(:method => 'template.get',
                                    :params =>
                                        {
                                            :output => 'extend',
                                            :hostids => [host['hostid']]
                                        }).collect{|t| t['host']}

      zabbix_hosts << new(:name => host['host'],
                          :hostid => host['hostid'],
                          :ip => first_interface['ip'],
                          :port => first_interface['port'],
                          :groups => zbx_groups.sort,
                          :templates => zbx_templates.sort,
                          :ensure => :present)
    end
    return zabbix_hosts
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      $zabbix_api || self.prepare_zabbix_connection(resource)
      if found = instances.find { |h| h.name == name }
        result = { :ensure => :present }
        result[:name] = found.name
        result[:hostid] = found.hostid
        result[:ip] = found.ip
        result[:port] = found.port
        result[:groups] = found.groups
        result[:templates] = found.templates
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
    api.hosts.create_or_update(:host => @resource[:name],
                                :groups => array_of_groupids,
                                :templates => array_of_templateids,
                                :interfaces => [
                                    {
                                    :type => 1,
                                    :main => 1,
                                    :ip => @resource[:ip],
                                    :dns => '',
                                    :port => @resource[:port],
                                    :useip => 1
                                    }
                                ]
    )
    @property_hash[:ensure] = :present
  end

  def destroy
    api.hosts.delete(api.hosts.get_id(:host => name))
    @property_hash.clear
  end

  def array_of_groupids
    zbx_groups = []
    if @resource[:groups]
      @resource[:groups].each do |group|
        id = api.hostgroups.get_or_create(:name => group)
        zbx_groups << { :groupid => id }
      end
    end
    return zbx_groups
  end

  def array_of_templateids(templates = @resource[:templates])
    zbx_templates = []
    if templates
      templates.each do |template|
        id = api.templates.get(:host => template).first["templateid"]
        zbx_templates << { :templateid => id }
      end
    end
    return zbx_templates
  end

  def replace_interfaces
    interface_id = api.query(:method => 'host.get',
                     :params => {
                         :selectInterfaces => 'extend',
                         :filter => {
                             'hostid' => [@property_hash[:hostid]]
                         }
                     }).first['interfaces'].first['interfaceid']

    api.query(:method =>'hostinterface.update',
              :params => {
                  :interfaceid => interface_id,
                  :ip => @resource[:ip],
                  :port => @resource[:port],
                  :useip => 1
              })
  end

  def update_groups
    api.query(:method =>'host.update',
              :params => {
                  :hostid => @property_hash[:hostid],
                  :groups => array_of_groupids,
              })
  end

  def update_templates
    templates_to_unlink = @property_hash[:templates] - @resource[:templates]

    if templates_to_unlink.length > 0
      api.query(:method =>'host.update',
                :params => {
                    :hostid => @property_hash[:hostid],
                    :templates_clear => array_of_templateids(templates_to_unlink),
                })
    end

    api.query(:method =>'host.update',
              :params => {
                  :hostid => @property_hash[:hostid],
                  :templates => array_of_templateids,
              })
  end

  def ip=(ip)
    replace_interfaces
  end

  def port=(port)
    replace_interfaces
  end

  def groups=(groups)
    update_groups
  end

  def templates=(templates)
    update_templates
  end
end