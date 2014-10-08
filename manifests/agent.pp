# Zabbix agent installation
class zabbix::agent (
  $bindir                   = $zabbix::agent::bindir,
  $confddir                 = $zabbix::agent::confddir,
  $sudofile                 = $zabbix::agent::sudofile,
  $zabbix_server_ssh_key    = ''
) {
  require 'zabbix'

  package { 'zabbix-agent':
    ensure  => installed,
  }

  user { 'zabbix':
    groups    => [adm, puppet, backup],
    shell     => '/bin/bash',
    require   => Package['zabbix-agent'],
    notify    => Service['zabbix-agent'],
  }

  if ($zabbix_server_ssh_key =~ /\w/) {
    ssh_authorized_key {'zabbix server public key':
      ensure    => 'present',
      key       => $zabbix_server_ssh_key,
      type      => 'ssh-rsa',
      user      => 'zabbix',
    }
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
      mode    => 'ug+x',
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
