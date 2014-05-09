# Zabbix user configuration
class zabbix::users (
  $apiuser        = undef,
  $apipassword    = undef,
  $adminpassword  = undef,
){
  require 'zabbix::server'
  require 'zabbix::frontend'

  # zabbix provider defaults
  Zabbix_host {
    ensure        => 'present',
    api_url       => 'http://127.0.0.1/api_jsonrpc.php',
    api_user      => $apiuser,
    api_password  => $apipassword,
  }

  Zabbix_template_file {
    ensure        => 'present',
    api_url       => 'http://127.0.0.1/api_jsonrpc.php',
    api_user      => $apiuser,
    api_password  => $apipassword,
  }

  Zabbix_login {
    ensure        => 'present',
    api_url       => 'http://127.0.0.1/api_jsonrpc.php',
    api_user      => $apiuser,
    api_password  => $apipassword,
  }

  Zabbix_hostgroup {
    ensure        => 'present',
    api_url       => 'http://127.0.0.1/api_jsonrpc.php',
    api_user      => $apiuser,
    api_password  => $apipassword,
  }

  Zabbix_usergroup {
    ensure        => 'present',
    api_url       => 'http://127.0.0.1/api_jsonrpc.php',
    api_user      => $apiuser,
    api_password  => $apipassword,
  }

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
      api_user      => $apiuser,
      api_password  => $apipassword,
    } ->

    zabbix_login {'Admin':
      ensure        => 'present',
      password      => $adminpassword,
      type          => 'Super Admin',
      usergroups    => ['Zabbix administrators'],
      api_url       => 'http://127.0.0.1/api_jsonrpc.php',
      api_user      => $apiuser,
      api_password  => $apipassword,
    }
  }

  # hiera support for zabbix types
  $zabbix_hostgroups = hiera_hash('zabbix::hostgroups', {})
  $zabbix_usergroups = hiera_hash('zabbix::usergroups', {})
  $zabbix_templates = hiera_hash('zabbix::templates', {})
  $zabbix_hosts = hiera_hash('zabbix::hosts', {})
  $zabbix_logins = hiera_hash('zabbix::logins', {})

  create_resources(zabbix_hostgroup, $zabbix_hostgroups)
  create_resources(zabbix_usergroup, $zabbix_usergroups)
  create_resources(zabbix_template_file, $zabbix_templates)
  create_resources(zabbix_host, $zabbix_hosts)
  create_resources(zabbix_login, $zabbix_logins)
}