require 'uri'

Puppet::Type.newtype(:zabbix_usergroup) do

  @doc = 'This type provides the capability to manage zabbix usergroups'

  ensurable

  newparam(:name, :namevar => true) do
    isrequired
    desc 'usergroup display name'
  end

  newproperty(:usergroupid) do
    desc 'usergroup id (readonly)'
    validate do |id|
      raise ArgumentError, 'groupid is read-only'
    end
  end

  newproperty(:guiaccess) do
    desc 'usergroup access to the frontend web interface'
    defaultto 'enabled'

    munge do |value|
      case
        when value == true
          0
        when value == false
          2
        when value.downcase == 'true'
          0
        when value.downcase =~ /true|yes|enable/
          0
        when value.downcase =~ /no|false|disable/
          2
      end
    end

    def should_to_s(newvalue)
      case newvalue
        when 0
          'enabled'
        when 2
          'disabled'
      end
    end

    def is_to_s(currentvalue)
      case currentvalue
        when '0'
          'enabled'
        when '2'
          'disabled'
      end
    end
  end

  newproperty(:status) do
    desc 'usergroup enabled or disabled switch'
    defaultto 'enabled'

    munge do |value|
      case
        when value == true
          0
        when value == false
          1
        when value.downcase =~ /true|yes|enable/
          0
        when value.downcase =~ /no|false|disable/
          1
      end
    end

    def should_to_s(newvalue)
      case newvalue
        when 0
          'enabled'
        when 1
          'disabled'
      end
    end

    def is_to_s(currentvalue)
      case currentvalue
        when '0'
          'enabled'
        when '1'
          'disabled'
      end
    end
  end

  newproperty(:debugmode) do
    desc 'usergroup set to debug mode'
    defaultto 'no'

    munge do |value|
      case
        when value == true
          1
        when value == false
          0
        when value.downcase =~ /true|yes|enable/
          1
        when value.downcase =~ /no|false|disable/
          0
      end
    end

    def should_to_s(newvalue)
      case newvalue
        when 1
          'enabled'
        when 0
          'disabled'
      end
    end

    def is_to_s(currentvalue)
      case currentvalue
        when '1'
          'enabled'
        when '0'
          'disabled'
      end
    end
  end

  newproperty(:initialreadaccess, :array_matching => :all) do
    desc 'list of hostgroups to which this group has read access to on creation of usergroup'
    defaultto []

    # unfortunately we cant check this through the Zabbix API
    def insync?(is)
      return true
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  newproperty(:initialwriteaccess, :array_matching => :all) do
    desc 'list of hostgroups to which this group has write access to on creation of usergroup'
    defaultto []

    # unfortunately we cant check this through the Zabbix API
    def insync?(is)
      return true
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  autorequire(:class) do
    [ 'zabbix::server', 'zabbix::frontend']
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