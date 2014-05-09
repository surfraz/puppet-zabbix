# Zabbix frontend installation
class zabbix::frontend {
  require zabbix

  package { 'libapache2-mod-php5':
    ensure    => installed,
  } ->

  package { 'zabbix-frontend-php':
    ensure    => installed,
  } ->

  # this significantly speeds up zabbix interface
  package { 'php5-xcache':
    ensure    => installed,
    notify    => Exec['reload apache config'],
  }

  file { '/usr/share/zabbix/robots.txt':
    ensure    => present,
    content   => template('zabbix/robots.txt.erb'),
    require   => Package['zabbix-frontend-php'],
  }

  file { '/etc/zabbix/web/zabbix.conf.php':
    ensure    => present,
    content   => template('zabbix/zabbix.conf.php.erb'),
    mode      => '0640',
    owner     => 'www-data',
    notify    => Exec['reload apache config'],
  }

  editfile::config { 'php timezone':
    ensure    => 'Europe/London',
    path      => '/etc/php5/apache2/php.ini',
    entry     => 'date.timezone',
    require   => Package['zabbix-frontend-php'],
    notify    => Exec['reload apache config'],
  }

  exec { 'change documentroot to zabbix':
    command   => 'sed -i \'s!DocumentRoot /var/www!DocumentRoot /usr/share/zabbix!\' /etc/apache2/sites-available/*',
    unless    => 'grep \'DocumentRoot /usr/share/zabbix\' /etc/apache2/sites-available/default',
    require   => Package['zabbix-frontend-php'],
    notify    => Exec['reload apache config'],
    path      => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],

  }

  exec { 'reload apache config':
    command       => 'service apache2 reload',
    refreshonly   => true,
    path          => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  }
}
