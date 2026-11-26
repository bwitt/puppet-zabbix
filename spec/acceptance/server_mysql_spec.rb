# frozen_string_literal: true

require 'spec_helper_acceptance'

zabbix_version = ENV.fetch('BEAKER_FACTER_zabbix_version', '7.0')

describe 'zabbix::server class with a mysql database', unless: default[:platform] =~ %r{archlinux} do
  before(:all) do
    prepare_host
  end

  it_behaves_like 'an idempotent resource' do
    let(:manifest) do
      <<-PUPPET
      class { 'zabbix::database':
        database_type => 'mysql',
      }
      -> class { 'zabbix::server':
        database_type  => 'mysql',
        zabbix_version => "#{zabbix_version}",
      }
      PUPPET
    end
  end

  describe package('zabbix-server-mysql') do
    it { is_expected.to be_installed }
  end

  describe service('zabbix-server') do
    it { is_expected.to be_running }
    it { is_expected.to be_enabled }
  end

  describe command("mysql -N -e 'select count(*) from zabbix_server.users'") do
    its(:stdout) { is_expected.to match %r{^[1-9]} }
  end
end
