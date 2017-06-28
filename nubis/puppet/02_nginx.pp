$port = 80

# Install our service discovery handy helper
include nubis_discovery
nubis::discovery::service { $project_name:
  tags     => [ 'nginx', '%%PROJECT%%' ],
  port     => $port,
  check    => "/usr/bin/curl -If http://localhost:${port}",
  interval => '30s',
}

# Install a simple webserver
class { 'nginx': }

nginx::resource::vhost { 'default':
  listen_port => $port,
  www_root    => '/var/www/html',
}

# With a simple hello world page
file { [ '/var/www', '/var/www/html' ]:
  ensure => directory,
  owner  => root,
  group  => root,
  mode   => '0755',
}->
file { '/var/www/html/index.html':
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0755',
    source => 'puppet:///nubis/files/index.html' #lint:ignore:puppet_url_without_modules
}
