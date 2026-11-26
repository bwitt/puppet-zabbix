# frozen_string_literal: true

def prepare_host
  shell('yum clean all --verbose; rm -rf /etc/yum.repos.d/Zabbix*.repo') if fact('os.family') == 'RedHat'

  apply_manifest <<~PUPPET
    $services = $facts['os']['family'] ? {
      'RedHat' => ['zabbix-server', 'zabbix-proxy', 'httpd', 'zabbix-agentd', 'zabbix-agent', 'zabbix-agent2'],
      'Debian' => ['zabbix-server', 'zabbix-proxy', 'apache2', 'zabbix-agentd', 'zabbix-agent', 'zabbix-agent2'],
      default  => ['zabbix-agentd', 'zabbix-agent', 'zabbix-agent2'],
    }
    service { $services:
      ensure => stopped
    }

    $packages = $facts['os']['family'] ? {
      'RedHat' => ['zabbix-server-pgsql', 'zabbix-server-pgsql-scl', 'zabbix-server-mysql', 'zabbix-proxy-pgsql', 'zabbix-web', 'zabbix-web-pgsql', 'zabbix-web-pgsql-scl', 'zabbix-frontend-php', 'zabbix-sql-scripts', 'zabbix-agent', 'zabbix-agent2'],
      'Debian' => ['zabbix-server-pgsql', 'zabbix-server-mysql', 'zabbix-proxy-pgsql', 'zabbix-web-pgsql', 'zabbix-frontend-php', 'zabbix-sql-scripts', 'zabbix-agent', 'zabbix-agent2'],
      default  => ['zabbix-agent', 'zabbix-agent2'],
    }

    $pkg_ensure = $facts['os']['family'] ? {
      'Archlinux' => absent,
      default     => purged,
    }

    package { $packages:
      ensure => $pkg_ensure
    }
  PUPPET

  shell <<~SHELL
    /opt/puppetlabs/puppet/bin/gem uninstall zabbixapi -a
    rm -f /etc/zabbix/.*done
    if id postgres > /dev/null 2>&1; then
      su - postgres -c "psql -c 'drop database if exists zabbix_server;'"
      su - postgres -c "psql -c 'drop database if exists zabbix_proxy;'"
    fi
  SHELL
end
