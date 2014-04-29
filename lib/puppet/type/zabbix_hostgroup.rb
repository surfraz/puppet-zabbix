require 'uri'

Puppet::Type.newtype(:zabbix_hostgroup) do

  @doc = 'This type provides the capability to manage zabbix hostgroups'

  ensurable

  newparam(:name, :namevar => true) do
    isrequired
    desc 'hostgroup display name'
  end

  newproperty(:groupid) do
    desc 'hostgroup id (readonly)'
    validate do |id|
      raise ArgumentError, 'groupid is read-only'
    end
  end

  newproperty(:flags) do
    desc 'hostgroup flags are (readonly)'
    validate do |flags|
      raise ArgumentError, 'flags is read-only'
    end
  end

  newproperty(:internal) do
    desc 'hostgroup internal (readonly)'
    validate do |internal|
      raise ArgumentError, 'internal is read-only'
    end
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