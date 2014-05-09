# Zabbix user configuration
class zabbix::users (
  $apiuser        = undef,
  $apipassword    = undef,
  $adminpassword  = undef,
){
require 'zabbix::server'
require 'zabbix::frontend'

# set up API user and set admin password
  if $apiuser and $apipassword {
    zabbix_login {$apiuser:
      ensure        => 'present',
      firstname     => 'Puppet',
      lastname      => 'Apiuser',
      password      => $apipassword,
      type          => 'Super Admin',
      usergroups    => ['Zabbix administrators'],
      api_url       => 'http://127.0.0.1/api_jsonrpc.php',
      api_user      => 'Admin',
      api_password  => 'zabbix',
    } #~>

    #zabbix_login {'Admin':
    #  ensure        => 'present',
    #  password      => $adminpassword,
    #  type          => 'Super Admin',
    #  usergroups    => ['Zabbix administrators'],
    #  api_url       => 'http://127.0.0.1/api_jsonrpc.php',
    #  api_user      => $apiuser,
    #  api_password  => $apipassword,
    #  refreshonly   => 'true',
    #}
  }
}