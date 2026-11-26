# frozen_string_literal: true

require 'spec_helper_acceptance'

zabbix_version = ENV.fetch('BEAKER_FACTER_zabbix_version', '7.0')

# Archlinux is not supported by zabbix::proxy
describe "zabbix::proxy class with zabbix_version #{zabbix_version}", unless: default[:platform] =~ %r{archlinux} do
  before(:all) do
    prepare_host
  end

  context 'with a postgresql database' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<-PUPPET
        class { 'zabbix::proxy':
          zabbix_server_host => '127.0.0.1',
          zabbix_version     => '#{zabbix_version}',
        }
        PUPPET
      end
    end

    describe package('zabbix-proxy-pgsql') do
      it { is_expected.to be_installed }
    end

    describe service('zabbix-proxy') do
      it { is_expected.to be_running }
      it { is_expected.to be_enabled }
    end

    describe port(10_051) do
      it { is_expected.to be_listening }
    end

    describe command('zabbix_proxy -T -c /etc/zabbix/zabbix_proxy.conf') do
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command("su - postgres -c \"psql -d zabbix_proxy -tAc 'select count(*) from dbversion'\"") do
      its(:stdout) { is_expected.to match %r{^1$} }
    end
  end
end
