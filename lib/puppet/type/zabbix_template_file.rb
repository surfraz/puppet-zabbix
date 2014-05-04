require 'uri'

Puppet::Type.newtype(:zabbix_template_file) do

  @doc = 'This type provides the capability to import a zabbix xml file template'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'template name'
    isrequired
  end

  newparam(:xml) do
    desc 'xml template string to upload'
  end

  newparam(:templateid) do
    desc 'template internal id'
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