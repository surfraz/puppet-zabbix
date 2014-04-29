require 'spec_helper'

describe 'zabbix::db' do
  context 'As a Web Operations Engineer' do
    context 'When I install Zabbix on Ubuntu' do

      let :facts do {
        :osfamily  => 'Debian',
        :lsbdistid => 'Ubuntu'
      }
      end

      describe 'by default it' do

        it 'should compile without error' do
          should compile.with_all_deps
        end

        it 'should include zabbix::server' do
          should contain_zabbix__server
        end

        it 'should include mysql::server' do
          should contain_mysql__server
        end

        it 'should create zabbix db' do
          should contain_mysql__db('zabbix').with(
              :require      => 'Class[Mysql::Server]'
                 )

          should contain_exec('zabbix db schema').with(
              :command      => /schema\.sql/,
              :unless       => /test -f/,
              :require      => [ 'Mysql::Db[zabbix]', 'Package[zabbix-server-mysql]' ]
                 )

          should contain_exec('zabbix db images').with(
                     :command      => /images\.sql/,
                     :unless       => /test -f/,
                 )

          should contain_exec('zabbix db data').with(
                     :command      => /data\.sql/,
                     :unless       => /test -f/,
                     :notify       => 'Service[zabbix-server]',
          )
        end
      end
    end
  end
end