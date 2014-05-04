require 'uri'

Puppet::Type.newtype(:zabbix_host) do

  @doc = 'This type provides the capability to manage zabbix host'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'host technical name'
    isrequired
  end

  newproperty(:groups, :array_matching => :all) do
    desc 'groups the host belongs to'
    defaultto ['default group']

    def insync?(is)
      should = @should
      if is.sort == should.sort
        return true
      else
        return false
      end
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  newproperty(:templates, :array_matching => :all) do
    desc 'template the host has assigned'

    def insync?(is)
      should = @should
      if is.sort == should.sort
        return true
      else
        return false
      end
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  autorequire(:zabbix_template_file) do
    [self[:templates]]
  end

  autorequire(:service) do
    'zabbix-server'
  end

  newproperty(:ip) do
    desc 'ip interface defined on host'
    defaultto '127.0.0.1'
  end

  newproperty(:port) do
    desc 'ip interface defined on host'
    defaultto '10050'
  end

  newparam(:hostid) do
    desc 'hosts internal id'
  end

  # these params are for API access
  newparam(:api_url) do
    desc 'API access URL'
    validate do |url|
      unless url =~ URI::regexp or url.empty?
        raise ArgumentError, 'provided api_url is not a valid URL'
      end
    end
  end

  newparam(:api_user) do
    desc 'API access username'
    validate do |user|
      if user.empty?
        raise ArgumentError, 'you need to provide an API username'
      end
    end
  end

  newparam(:api_password) do
    desc 'API access password'
    validate do |password|
      if password.empty?
        raise ArgumentError, 'provided api_url is not a valid URL'
      end
    end
  end
end