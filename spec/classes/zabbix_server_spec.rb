require 'spec_helper'

describe 'zabbix::server' do
  context 'As a Web Operations Engineer' do
    context 'When I install Zabbix Server on Ubuntu' do

      let :facts do {
        :osfamily  => 'Debian',
        :lsbdistid => 'Ubuntu'
      }
      end

      describe 'by default it' do

        it 'should compile without error' do
          should compile.with_all_deps
        end

        it 'should inherit zabbix' do
          should contain_zabbix
        end

        it 'should install required packages' do
          should contain_package('zabbix-server-mysql').with(
              :ensure   => 'installed',
                 )

          should contain_package('zabbix-java-gateway').with(
              :ensure   => 'installed',
                 )

          should contain_file('/etc/init.d/zabbix-java-gateway').with(
              :ensure   => 'present',
              :owner    => 'root',
              :group    => 'root',
              :mode     => '0755',
              :before   => 'Package[zabbix-java-gateway]',
                 )
        end

        it 'should ensure recommended sysctl settings are applied' do
          should contain_file('/etc/sysctl.d/20-zabbix.conf').with(
              :ensure   => 'file',
              :content  => 'kernel.shmmax=536870912',
                 )

          should contain_exec('shmmax for zabbix').with(
              :command  => 'sysctl -w kernel.shmmax=536870912',
              :unless   => 'sysctl -a | grep "kernel.shmmax = " | grep 536870912',
              :path     => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
                 )
        end

        it 'should manage zabbix configuration files' do
          should contain_file('/etc/zabbix/zabbix_server.conf').with(
              :ensure     => 'present',
              :notify     => 'Service[zabbix-server]',
              :require    => 'Package[zabbix-server-mysql]',
                 )
        end

        it 'should ensure zabbix services are running' do
          should contain_service('zabbix-server').with(
              :ensure     => 'running',
              :enable     => 'true',
              :require    => 'File[/etc/zabbix/zabbix_server.conf]'
                 )

          should contain_service('zabbix-java-gateway').with(
                     :ensure     => 'running',
                     :enable     => 'true',
                     :require    => [ 'File[/etc/init.d/zabbix-java-gateway]', 'Package[zabbix-java-gateway]' ]
                 )
        end
      end
    end
  end
end