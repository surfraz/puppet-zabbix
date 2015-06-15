# == Class: zabbix
#
# Full description of class zabbix here.
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class zabbix (
  $dbuser       = $zabbix::dbuser,
  $dbpassword   = $zabbix::dbpassword,
  $dbserver     = $zabbix::dbserver,
  $server       = $zabbix::server,
  $repo_version = '2.4'
) {

  # only works on Ubuntu at the moment
  if $::operatingsystem != 'Ubuntu' {
    fail("unsupported operating system: $::operatingsystem")
  }

  file { '/etc/apt/sources.list.d/zabbix.list':
    ensure    => 'file',
    owner     => 'root',
    group     => 'root',
    content   => template('zabbix/zabbix_apt_repo.erb')
  }

}
