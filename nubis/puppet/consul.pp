# Enable consul-template, base doesn't enable it yet
class { 'consul_template':
    service_enable => true,
    service_ensure => 'stopped',
    version        => '0.16.0',
    user           => 'root',
    group          => 'root',
}

# Drop our template
file { "${consul_template::config_dir}/${project_name}-peers.php.ctmpl":
  ensure  => file,
  owner   => root,
  group   => root,
  mode    => '0644',
  source  => 'puppet:///nubis/files/peers.php.ctmpl',
  require => [
    Class['consul_template'],
  ],
}

# Configure our navigation links
consul_template::watch { 'peers.php':
    source      => "${consul_template::config_dir}/${project_name}-peers.php.ctmpl",
    destination => '/etc/nubis-config/peers.php',
    command     => '/bin/true',
}

# Drop our template
file { "${consul_template::config_dir}/${project_name}-acl.ctmpl":
  ensure  => file,
  owner   => root,
  group   => root,
  mode    => '0644',
  source  => 'puppet:///nubis/files/acl.ctmpl',
  require => [
    Class['consul_template'],
  ],
}

# Configure our navigation links
consul_template::watch { 'acl':
    source      => "${consul_template::config_dir}/${project_name}-acl.ctmpl",
    destination => '/etc/varnish/includes/acls.vcl',
    command     => '/usr/share/varnish/reload-vcl',
}
