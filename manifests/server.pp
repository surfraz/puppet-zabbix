# Zabbix server installation
class zabbix::server (
  $apiuser        = undef,
  $apipassword    = undef,
  $adminpassword  = undef,
){
  require zabbix
#  require jre

  package { 'zabbix-server-mysql':
    ensure  => installed,
  }

  file { '/etc/sysctl.d/20-zabbix.conf':
    ensure    => file,
    content   => 'kernel.shmmax=536870912',
  }

  exec { 'shmmax for zabbix':
    command   => 'sysctl -w kernel.shmmax=536870912',
    unless    => 'sysctl -a | grep "kernel.shmmax = " | grep 536870912',
    path      => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  }

  file { '/etc/init.d/zabbix-java-gateway':
    ensure    => present,
    content   => template('zabbix/zabbix_java_gateway.init.erb'),
    owner     => 'root',
    group     => 'root',
    mode      => '0755',
    before    => Package['zabbix-java-gateway'],
  }

  package { 'zabbix-java-gateway':
    ensure  => installed,
  }

  file { '/etc/zabbix/zabbix_server.conf':
    ensure  => present,
    content => template('zabbix/zabbix_server.conf.erb'),
    notify  => Service['zabbix-server'],
    require => Package['zabbix-server-mysql'],
  }

  file { '/usr/lib/zabbix/externalscripts/run_via_ssh.sh':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/zabbix/scripts/run_via_ssh.sh',
    require => Package['zabbix-server'],
  }

  service {'zabbix-server':
    ensure    => running,
    enable    => true,
    provider  => 'upstart',
    require   => File['/etc/zabbix/zabbix_server.conf'],
  }

  service {'zabbix-java-gateway':
    ensure    => running,
    enable    => true,
    provider  => 'upstart',
    require   => [ File['/etc/init.d/zabbix-java-gateway'],
                  Package['zabbix-java-gateway'], ],
  }

}
