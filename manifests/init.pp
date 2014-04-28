# == Class: zabbix
#
# Full description of class zabbix here.
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class zabbix (
  $dbuser      = $zabbix::dbuser,
  $dbpassword  = $zabbix::dbpassword,
  $dbserver    = $zabbix::dbserver,
  $server      = $zabbix::server
) {

  # only works on Ubuntu at the moment
  if $::osfamily != 'Debian' {
    fail("unsupported osfamily: $::osfamily")
  }

  require 'wget'

  wget::fetch { 'zabbix repo installer':
    source        => 'http://repo.zabbix.com/zabbix/2.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_2.2-1+precise_all.deb',
    destination   => '/var/tmp/zabbix-release_2.2-1+precise_all.deb',
    timeout       => '60',
    verbose       => false,
  }

  exec { 'install zabbix repo':
    command     => 'dpkg -i /var/tmp/zabbix-release_2.2-1+precise_all.deb && apt-get update',
    unless      => 'test -f /etc/apt/sources.list.d/zabbix.list',
    require     => Wget::Fetch['zabbix repo installer'],
    path        => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  }

}
