# zabbix server database
class zabbix::db {
  include zabbix::server
  require mysql::server

  mysql::db { 'zabbix':
    user     => $zabbix::dbuser,
    password => $zabbix::dbpassword,
    host     => $zabbix::dbserver,
    grant    => ['SELECT','INSERT','UPDATE','DELETE','CREATE','DROP','ALTER','INDEX'],
    require  => Class['Mysql::Server'],
  }

  $schemapath = '/usr/share/zabbix-server-mysql'
  $defaults = '--defaults-extra-file=/root/.my.cnf'

  exec { 'zabbix db schema':
    command   => "mysql ${defaults} zabbix < ${schemapath}/schema.sql && touch ${schemapath}/.schema.loaded",
    unless    => "test -f ${schemapath}/.schema.loaded",
    require   => [ Mysql::Db['zabbix'], Package['zabbix-server-mysql'] ],
    path      => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  } ->

  exec { 'zabbix db images':
    command   => "mysql ${defaults} zabbix < ${schemapath}/images.sql && touch ${schemapath}/.images.loaded",
    unless    => "test -f ${schemapath}/.images.loaded",
    path      => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  } ->

  exec { 'zabbix db data':
    command   => "mysql ${defaults} zabbix < ${schemapath}/data.sql && touch ${schemapath}/.data.loaded",
    unless    => "test -f ${schemapath}/.data.loaded",
    notify    => Service['zabbix-server'],
    path      => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  }
}
