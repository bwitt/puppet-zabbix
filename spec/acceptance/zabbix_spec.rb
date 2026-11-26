# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'serverspec_type_zabbixapi'

zabbix_version = ENV.fetch('BEAKER_FACTER_zabbix_version', '7.0')

# zabbix::web is unsupported on Arch
describe "zabbix class with zabbix_version #{zabbix_version}", unless: default[:platform] =~ %r{archlinux} do
  before(:all) do
    prepare_host
  end

  it_behaves_like 'an idempotent resource' do
    let(:manifest) do
      <<-PUPPET
      class { 'zabbix':
        zabbix_version => '#{zabbix_version}',
        zabbix_url     => 'localhost',
      }
      PUPPET
    end
  end

  describe service('zabbix-server') do
    it { is_expected.to be_running }
    it { is_expected.to be_enabled }
  end

  describe port(10_051) do
    it { is_expected.to be_listening }
  end

  describe command('curl -s -L http://localhost/') do
    its(:stdout) { is_expected.to match %r{<title>[^<]*Zabbix</title>} }
  end

  describe zabbixapi('localhost', 'Admin', 'zabbix', 'apiinfo.version', {}) do
    its(:result) { is_expected.to start_with("#{zabbix_version}.") }
  end

  # Authenticates with an "Authorization: Bearer" header
  describe zabbixapi('localhost', 'Admin', 'zabbix', 'user.get', { output: ['username'], filter: { username: 'Admin' } }) do
    its(:result) { is_expected.to eq([{ 'userid' => '1', 'username' => 'Admin' }]) }
  end
end
