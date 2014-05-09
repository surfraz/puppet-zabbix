# Zabbix agent installation
class zabbix::agent (
  $bindir     = $zabbix::agent::bindir,
  $confddir   = $zabbix::agent::confddir,
  $sudofile   = $zabbix::agent::sudofile,
) {
  require 'zabbix'

  package { 'zabbix-agent':
    ensure  => installed,
  }

  user { 'zabbix':
    groups    => [adm, puppet, backup],
    require   => Package['zabbix-agent'],
    notify    => Service['zabbix-agent'],
  }

  file { '/var/lib/zabbix':
    ensure  => 'directory',
    owner   => 'zabbix',
    group   => 'zabbix',
  }

  if defined(Class[mysql::server]) {
    # we need this to monitor the zabbix mysql server
    file { '/var/lib/zabbix/.my.cnf':
      ensure  => 'present',
      source  => '/root/.my.cnf',
      mode    => '0600',
      owner   => 'zabbix',
      group   => 'zabbix',
    }
  }

  file { '/etc/zabbix/zabbix_agentd.conf':
    ensure  => present,
    content => template('zabbix/zabbix_agentd.conf.erb'),
    notify  => Service['zabbix-agent'],
    require => Package['zabbix-agent'],
  }

  unless $bindir == undef {
    file { '/etc/zabbix/bin':
      ensure  => directory,
      source  => $bindir,
      recurse => true,
      owner   => 'zabbix',
      group   => 'zabbix',
      notify  => Service['zabbix-agent'],
      require => Package['zabbix-agent'],
    }
  }

  unless $confddir == undef {
    file { '/etc/zabbix/zabbix_agentd.d':
      ensure  => directory,
      source  => $confddir,
      recurse => true,
      owner   => 'zabbix',
      group   => 'zabbix',
      notify  => Service['zabbix-agent'],
      require => Package['zabbix-agent'],
    }
  }

  unless $sudofile == undef {
    file { '/etc/sudoers.d/zabbix':
      ensure  => present,
      source  => $sudofile,
      owner   => 'root',
      group   => 'root',
      mode    => '0440',
      notify  => Service['zabbix-agent'],
      require => Package['zabbix-agent'],
    }
  }

  service {'zabbix-agent':
    ensure    => running,
    enable    => true,
    provider  => 'upstart',
    require   => File['/etc/zabbix/zabbix_agentd.conf'],
  }
}
