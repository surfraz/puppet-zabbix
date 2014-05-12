require 'uri'
require 'xmlsimple'

def xml_cmp(a, b)
  a = XmlSimple.xml_in(a.to_s, 'normalisespace' => 2).to_hash
  b = XmlSimple.xml_in(b.to_s, 'normalisespace' => 2).to_hash
  a == b
end

Puppet::Type.newtype(:zabbix_template_file) do

  @doc = 'This type provides the capability to import a zabbix xml file template'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'template name'
    isrequired
  end

  newproperty(:xml) do
    desc 'xml template string to upload'

    # strip date value to aid comparision
    munge do |value|
      value.gsub(/<date>.*<\/date>/, '')
    end

    def insync?(is)
      xml_cmp(is, @should)
    end

    def should_to_s(newvalue)
      XmlSimple.xml_in(newvalue, 'normalisespace' => 2).hash
    end

    def is_to_s(currentvalue)
      XmlSimple.xml_in(currentvalue, 'normalisespace' => 2).hash
    end
  end

  newparam(:templateid) do
    desc 'template internal id'
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