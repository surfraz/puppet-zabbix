# Elasticsearch gem installation
class zabbix::elasticsearch {
  require 'zabbix::agent'

  package { 'elasticsearch':
    ensure          => installed,
    provider        => 'gem',
    install_options => '--no-user-install',
  }
}
