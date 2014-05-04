require 'spec_helper'

describe 'zabbix::agent' do
  context 'As a Web Operations Engineer' do
    context 'When I install Zabbix Agent on Ubuntu' do

      let :facts do {
        :osfamily  => 'Debian',
        :lsbdistid => 'Ubuntu'
      }
      end

      let :params do {
        :bindir => '/etc/puppet/bin',
        :confddir => 'puppet://files/zabbix/confdir',
        :sudofile => 'puppet://modules/zabbix/somesudofile',
      }
      end

      describe 'by default it' do

        it 'should compile without error' do
          should compile.with_all_deps
        end

        it 'should require zabbix' do
          should contain_zabbix
        end

        it 'should create a zabbix user account' do
          should contain_user('zabbix').with(
              :groups   => ['adm', 'puppet', 'backup'],
              :require  => 'Package[zabbix-agent]',
              :notify    => 'Service[zabbix-agent]',
                 )

          should contain_file('/var/lib/zabbix').with(
              :owner    => 'zabbix',
              :group    => 'zabbix',
                 )
        end

        it 'should copy mysql login file to zabbix home directory' do
          should contain_file('/var/lib/zabbix/.my.cnf').with(
              :source   => '/root/.my.cnf',
              :mode     => '0600',
              :owner    => 'zabbix',
              :group    => 'zabbix',
                 )
        end

        it 'should install zabbix agent with configuration' do
          should contain_package('zabbix-agent').with(
              :ensure   => 'installed',
                 )

          should contain_file('/etc/zabbix/zabbix_agentd.conf').with(
              :ensure   => 'present',
              :content  => /Server=/,
                 )

          should contain_file('/etc/zabbix/bin').with(
              :ensure   => 'directory',
              :source   => params[:bindir],
              :recurse  => true,
              :owner    => 'zabbix',
              :group    => 'zabbix',
              :notify   => 'Service[zabbix-agent]',
              :require  => 'Package[zabbix-agent]',
                 )

          should contain_file('/etc/zabbix/zabbix_agentd.d').with(
              :ensure   => 'directory',
              :source   => params[:confddir],
              :recurse  => true,
              :owner    => 'zabbix',
              :group    => 'zabbix',
              :notify   => 'Service[zabbix-agent]',
              :require  => 'Package[zabbix-agent]',
                 )

          should contain_file('/etc/sudoers.d/zabbix').with(
              :ensure   => 'present',
              :source   => params[:sudofile],
              :owner    => 'root',
              :group    => 'root',
              :mode     => '0440',
              :notify   => 'Service[zabbix-agent]',
              :require  => 'Package[zabbix-agent]',
                 )
        end

        it 'should start and enable the zabbix agent service' do
          should contain_service('zabbix-agent').with(
              :ensure   => 'running',
              :enable   => true,
              :require  => 'File[/etc/zabbix/zabbix_agentd.conf]',
                 )
        end
      end
    end
  end
end