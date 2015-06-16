# == Class: zabbix
#
# Full description of class zabbix here.
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class zabbix (
  $dbuser             = $zabbix::dbuser,
  $dbpassword         = $zabbix::dbpassword,
  $dbserver           = $zabbix::dbserver,
  $server             = $zabbix::server,
  $use_official_repo  = true,
  $repo_version       = '2.4'
) {

  # only works on Ubuntu at the moment
  if $::operatingsystem != 'Ubuntu' {
    fail("unsupported operating system: $::operatingsystem")
  }

  if $use_official_repo == 'true' {
    file { '/etc/apt/sources.list.d/zabbix.list':
      ensure    => 'file',
      owner     => 'root',
      group     => 'root',
      content   => template('zabbix/zabbix_apt_repo.erb')
    }

    file { '/var/lib/puppet/zabbix-repo-gpg.key':
      ensure    => 'file',
      owner     => 'root',
      group     => 'root',
      content   => template('zabbix/zabbix_repo_gpg.key')
    } ->

    exec { 'import zabbix gpg key':
      command   => 'cat /var/lib/puppet/zabbix-repo-gpg.key | apt-key add -',
      unless    => 'apt-key list | grep "1024D/79EA5ED4"',
      path      => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    }
  }
}
