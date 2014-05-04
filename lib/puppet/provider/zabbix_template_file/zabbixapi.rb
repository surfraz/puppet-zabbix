require 'rubygems'
require 'zabbixapi'
require 'pp'

Puppet::Type.type(:zabbix_template_file).provide(:zabbixapi) do

  confine :kernel => 'Linux'
  defaultfor :kernel => 'Linux'

  mk_resource_methods

  def self.prepare_zabbix_connection(resource)
    $zabbix_api ||= ZabbixApi.connect( :url => resource[:api_url], :user => resource[:api_user], :password => resource[:api_password] )
  end

  def self.instances
    zabbix_templates = []
    templates = $zabbix_api.templates.get(:id => 0)
    templates.each do |template|
      zabbix_templates << new(:name => template['host'], :templateid => template['templateid'], :ensure => :present)
    end
    return zabbix_templates
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      $zabbix_api || self.prepare_zabbix_connection(resource)
      if found = instances.find { |h| h.name == name }
        result = { :ensure => :present }
        result[:name] = found.name
        result[:templateid] = found.templateid
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
    api.query(
        :method => 'configuration.import',
        :params => {
            :format => 'xml',
            :rules  => {
                :applications => {
                    :createMissing => true,
                    :updateExisting => true,
                },
                :discoveryRules => {
                    :createMissing => true,
                    :updateExisting => true,
                },
                :graphs => {
                    :createMissing => true,
                    :updateExisting => true,
                },
                :items => {
                    :createMissing => true,
                    :updateExisting => true,
                },
                :maps => {
                    :createMissing => true,
                    :updateExisting => true,
                },
                :screens => {
                    :createMissing => true,
                    :updateExisting => true,
                },
                :templateLinkage => {
                    :createMissing => true,
                    :updateExisting => true,
                },
                :templates => {
                    :createMissing => true,
                    :updateExisting => true,
                },
                :templateScreens => {
                    :createMissing => true,
                    :updateExisting => true,
                },
                :triggers => {
                    :createMissing => true,
                    :updateExisting => true,
                },
            },
            :source => "#{@resource[:xml]}"
        }
    )
    @property_hash[:ensure] = :present
  end

  def destroy
    api.templates.delete(templateid)
    @property_hash.clear
  end

end