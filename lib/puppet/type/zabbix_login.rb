require 'uri'

Puppet::Type.newtype(:zabbix_login) do

  @doc = 'This type provides the capability to manage zabbix users'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'user login name'
    isrequired
  end

  newproperty(:firstname) do
    desc 'user first name'
    isrequired
  end

  newproperty(:lastname) do
    desc 'user last name'
    isrequired
  end

  newproperty(:type) do
    desc 'user admin level'
    isrequired
    defaultto 'user'

    munge do |value|
      case
        when value.downcase =~ /^user/
          1
        when value.downcase =~ /super/
          3
        when value.downcase =~ /admin/
          2
      end
    end

    def should_to_s(newvalue)
      case newvalue
        when 1
          'Zabbix User'
        when 2
          'Zabbix Admin'
        when 3
          'Zabbix Super Admin'
      end
    end

    def is_to_s(currentvalue)
      case currentvalue
        when '1'
          'Zabbix User'
        when '2'
          'Zabbix Admin'
        when '3'
          'Zabbix Super Admin'
      end
    end
  end

  newproperty(:userid) do
    desc 'user id (readonly)'
    validate do |id|
      raise ArgumentError, 'userid is read-only'
    end
  end

  newproperty(:password) do
    desc 'users password'

    # we cannot read this obviously!
    def isinsync?(is)
      true
    end
  end

  newproperty(:usergroups, :array_matching => :all) do
    desc 'groups the user belongs to'
    defaultto ['Disabled']

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
  end

  autorequire(:zabbix_usergroup) do
    [self[:usergroups]]
  end

  autorequire(:service) do
    'zabbix-server'
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