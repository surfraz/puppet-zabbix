require 'spec_helper'

describe 'zabbix' do
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

        it 'should require wget' do
          should contain_wget
        end

        it 'should install zabbix repo' do
          should contain_wget__fetch('zabbix repo installer').with(
              :source       => /repo.zabbix.com/,
              :destination  => /\/var\/tmp/,
                 )

          should contain_exec('install zabbix repo').with(
              :command      => /dpkg -i/,
              :unless       => 'test -f /etc/apt/sources.list.d/zabbix.list',
              :require      => 'Wget::Fetch[zabbix repo installer]',
              :path         => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
                 )
        end

      end
    end
  end
end