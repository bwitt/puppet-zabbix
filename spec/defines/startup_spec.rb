# frozen_string_literal: true

require 'spec_helper'

describe 'zabbix::startup', type: :define do # rubocop:disable RSpec/MultipleDescribes
  let(:title) { 'zabbix-agent' }
  let :pre_condition do
    'service{"zabbix-agent":}'
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      context 'on legacy init systems' do
        ['false', false].each do |systemd_fact_state|
          let :facts do
            os_facts.merge({ systemd: systemd_fact_state })
          end

          context 'it works' do
            let :params do
              {
                agent_configfile_path: '/something',
              }
            end

            case os_facts[:os]['family']
            when 'Debian'
              it do
                is_expected.to contain_file('/etc/init.d/zabbix-agent').with(
                  ensure: 'file',
                  content: %r{DAEMON_OPTS="-c /something"},
                )
              end
            when 'RedHat'
              it do
                is_expected.to contain_file('/etc/init.d/zabbix-agent').with(
                  ensure: 'file',
                  content: %r{OPTS="/something"},
                )
              end
            when 'windows'
              it { is_expected.to have_exec_resource_count(1) }
              it { is_expected.to contain_exec('install_agent_zabbix-agent') }
            else
              it { is_expected.not_to compile.with_all_deps }

              next
            end
            it { is_expected.not_to contain_class('systemd') }
            it { is_expected.not_to contain_file('/etc/systemd/system/zabbix-agent.service') }
          end
        end
      end

      next if os_facts[:os]['family'] == 'windows'

      context "#{os} on systemd" do
        ['true', true].each do |systemd_fact_state|
          let :facts do
            os_facts.merge({ systemd: systemd_fact_state })
          end

          context 'it works' do
            let :params do
              {
                agent_configfile_path: '/something',
                pidfile: '/somethingelse',
                additional_service_params: '--foreground',
              }
            end

            it { is_expected.to contain_class('systemd') }
            it { is_expected.to contain_systemd__unit_file('zabbix-agent.service') }
            it { is_expected.to contain_file('/etc/init.d/zabbix-agent').with_ensure('absent') }

            it do
              is_expected.to contain_file('/etc/systemd/system/zabbix-agent.service').with(
                ensure: 'file',
                mode: '0444',
              )
            end

            it { is_expected.to contain_file('/etc/systemd/system/zabbix-agent.service').with_content(%r{ExecStart=/usr/sbin/zabbix_agentd --foreground -c /something}) }
            it { is_expected.to contain_file('/etc/systemd/system/zabbix-agent.service').with_content(%r{PIDFile=/somethingelse}) }
          end
        end
      end
    end
  end
end

describe 'zabbix::startup', type: :define do
  let(:title) { 'zabbix-agent2' }
  let :pre_condition do
    'service{"zabbix-agent2":}'
  end

  on_supported_os.each do |os, os_facts|
    next unless %w[Debian RedHat].include?(os_facts[:os]['family'])

    context "on #{os}" do
      let :params do
        {
          agent_configfile_path: '/etc/zabbix/zabbix_agent2.conf',
          service_name: 'zabbix-agent',
          agent_daemon: 'zabbix_agent2',
        }
      end

      context 'on legacy init systems' do
        let :facts do
          os_facts.merge({ systemd: false })
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_file('/etc/init.d/zabbix-agent') }

        case os_facts[:os]['family']
        when 'Debian'
          it { is_expected.to contain_file('/etc/init.d/zabbix-agent2').with_content(%r{^NAME=zabbix_agent2$}) }
        when 'RedHat'
          it { is_expected.to contain_file('/etc/init.d/zabbix-agent2').with_content(%r{^ZABBIX_BIN="\$\(type -P zabbix_agent2\)"$}) }
        end
      end

      context 'on systemd' do
        let :facts do
          os_facts.merge({ systemd: true })
        end

        it { is_expected.to contain_file('/etc/init.d/zabbix-agent2').with_ensure('absent') }
        it { is_expected.to contain_file('/etc/systemd/system/zabbix-agent2.service').with_content(%r{^ExecStart=/usr/sbin/zabbix_agent2  -c /etc/zabbix/zabbix_agent2.conf$}) }
      end
    end
  end
end

describe 'zabbix::startup', type: :define do
  let(:title) { 'zabbix-server' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      context 'on legacy init systems' do
        ['false', false].each do |systemd_fact_state|
          let :facts do
            os_facts.merge({ systemd: systemd_fact_state })
          end

          context 'it works' do
            let :params do
              {
                server_configfile_path: '/something',
                database_type: 'mysql',
                manage_database: true,
              }
            end

            case os_facts[:os]['family']
            when 'Debian'
              it do
                is_expected.to contain_file('/etc/init.d/zabbix-server').with(
                  ensure: 'file',
                  content: %r{DAEMON_OPTS="-c /something"},
                )
              end
            when 'RedHat'
              it do
                is_expected.to contain_file('/etc/init.d/zabbix-server').with(
                  ensure: 'file',
                  content: %r{OPTS="/something"},
                )
              end
            else
              it { is_expected.not_to compile.with_all_deps }

              next
            end
            it { is_expected.not_to contain_class('systemd') }
            it { is_expected.not_to contain_file('/etc/systemd/system/zabbix-server.service') }
          end
        end
      end
    end

    next if os_facts[:os]['family'] == 'windows'

    context 'on systemd' do
      ['true', true].each do |systemd_fact_state|
        let :facts do
          os_facts.merge({ systemd: systemd_fact_state })
        end

        context 'it works on mysql' do
          let :params do
            {
              server_configfile_path: '/something',
              pidfile: '/somethingelse',
              database_type: 'mysql',
              additional_service_params: '--foreground',
              manage_database: true,
            }
          end

          it { is_expected.to contain_class('systemd') }
          it { is_expected.to contain_systemd__unit_file('zabbix-server.service') }
          it { is_expected.to contain_file('/etc/init.d/zabbix-server').with_ensure('absent') }

          it do
            is_expected.to contain_file('/etc/systemd/system/zabbix-server.service').with(
              ensure: 'file',
              mode: '0444',
            )
          end

          it { is_expected.to contain_file('/etc/systemd/system/zabbix-server.service').with_content(%r{ExecStart=/usr/sbin/zabbix_server --foreground -c /something}) }
          it { is_expected.to contain_file('/etc/systemd/system/zabbix-server.service').with_content(%r{PIDFile=/somethingelse}) }
          it { is_expected.to contain_file('/etc/systemd/system/zabbix-server.service').with_content(%r{After=mysqld.service}) }

          context 'and works on postgres' do
            let :params do
              {
                server_configfile_path: '/something',
                pidfile: '/somethingelse',
                database_type: 'postgresql',
                manage_database: true,
              }
            end

            it { is_expected.to contain_file('/etc/systemd/system/zabbix-server.service').with_content(%r{After=postgresql.service}) }
          end
        end
      end
    end
  end
end
