# Elasticsearch gem installation
class zabbix::elasticsearch {
  require 'zabbix::agent'

  exec {'install-elasticsearch-gem':
    command => 'gem install elasticsearch --no-user-install',
    onlyif  => 'gem list elasticsearch | grep -v "^elasticsearch"',
    path    => ['/bin', '/usr/bin', '/usr/sbin'],
  }
}
