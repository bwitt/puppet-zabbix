# frozen_string_literal: true

require 'spec_helper_acceptance'

zabbix_version = ENV.fetch('BEAKER_FACTER_zabbix_version', '7.0')

# Archlinux doesn't provide the zabbix-java-gateway package
describe "zabbix::javagateway class with zabbix_version #{zabbix_version}", unless: default[:platform] =~ %r{archlinux} do
  it_behaves_like 'an idempotent resource' do
    let(:manifest) do
      <<-PUPPET
      class { 'zabbix::javagateway':
        zabbix_version => '#{zabbix_version}',
      }
      PUPPET
    end
  end

  describe package('zabbix-java-gateway') do
    it { is_expected.to be_installed }
  end

  describe service('zabbix-java-gateway') do
    it { is_expected.to be_running }
    it { is_expected.to be_enabled }
  end

  describe port(10_052) do
    it { is_expected.to be_listening }
  end
end
