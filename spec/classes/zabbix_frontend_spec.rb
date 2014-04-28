require 'spec_helper'

describe 'zabbix::frontend' do
  context 'As a Web Operations Engineer' do
    context 'When I install Zabbix Frontend on Ubuntu' do

      let :facts do {
        :osfamily  => 'Debian',
        :lsbdistid => 'Ubuntu'
      }
      end

      describe 'by default it' do

        it 'should compile without error' do
          should compile.with_all_deps
        end

        it 'should require zabbix' do
          should contain_zabbix
        end

        it 'should install zabbix frontend package' do
          should contain_package('zabbix-frontend-php').with(
              :ensure       => 'installed',
                 )

          should contain_package('php5-xcache').with(
              :ensure     => 'installed',
              :notify     => 'Exec[reload apache config]',
                 )
        end

        it 'configure zabbix frontend' do
          should contain_file('/etc/zabbix/web/zabbix.conf.php').with(
              :ensure     => 'present',
              :content    => /ZBX_SERVER_PORT/,
              :mode       => '0640',
              :owner      => 'www-data',
              :notify     => 'Exec[reload apache config]',
                 )

          should contain_file('/usr/share/zabbix/robots.txt').with(
              :ensure     => 'present',
              :content      => /Disallow: \//,
              :require      => 'Package[zabbix-frontend-php]',
                 )

          should contain_editfile__config('php timezone').with(
              :ensure     => 'Europe/London',
              :entry      => 'date.timezone',
                 )

          should contain_exec('change documentroot to zabbix').with(
              :command    => /sed -i/,
              :unless     => /grep/,
              :require    => 'Package[zabbix-frontend-php]',
              :notify     => 'Exec[reload apache config]',
                 )
        end

        it 'should reload apache configuration' do
          should contain_exec('reload apache config').with(
              :command      => 'service apache2 reload',
              :refreshonly  => true,
                 )
        end
      end
    end
  end
end