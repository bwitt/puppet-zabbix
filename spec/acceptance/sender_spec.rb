# frozen_string_literal: true

require 'spec_helper_acceptance'

zabbix_version = ENV.fetch('BEAKER_FACTER_zabbix_version', '7.0')

describe "zabbix::sender class with zabbix_version #{zabbix_version}" do
  it_behaves_like 'an idempotent resource' do
    let(:manifest) do
      <<-PUPPET
      class { 'zabbix::sender':
        zabbix_version => '#{zabbix_version}',
      }
      PUPPET
    end
  end

  describe package('zabbix-sender') do
    it { is_expected.to be_installed }
  end

  describe command('zabbix_sender -V') do
    its(:stdout) { is_expected.to match %r{^zabbix_sender \(Zabbix\) #{Regexp.escape(zabbix_version)}\.} }
  end
end
