class { 'apt':
}

$varnish_exporter_version = '1.4'
$varnish_exporter_url = "https://github.com/jonnenauha/prometheus_varnish_exporter/releases/download/${varnish_exporter_version}/prometheus_varnish_exporter-${varnish_exporter_version}.linux-amd64.tar.gz"

Exec['apt_update'] -> Package['varnish']
Class['apache'] -> Class['varnish']

class {'varnish':
  varnish_listen_port  => 80,
  varnish_storage_size => '2G',
  version              => '4.1',
}

class {'varnish::ncsa':
  log_format => '%{X-Forwarded-For}i %l %u %t "%r" %s %b "%{Referer}i" "%{User-agent}i"',
  varnishncsa_daemon_opts => '-w /var/log/varnish/ncsa.log',
}

class { 'varnish::vcl':
  backends               => {}, # without this line you will not be able to redefine backend 'default'
  cookiekeeps            => [
    'wiki_session',
    'wikiUserID',
  ],
  logrealip              => true,
  honor_backend_ttl      => true,
  cond_requests          => true,
  https_redirect         => true,
  x_forwarded_proto      => true,
  pipe_uploads           => true,
  purgeips               => [ '127.0.0.1' ],
  unset_headers          => [],
  unset_headers_debugips => [],
  cond_unset_cookies     => '
    # Static file cache
    req.url ~ "^/(assets|extensions|images|skins|resources)/" ||
    req.url ~ "^/load.php(\?.*)?$"
',
}

varnish::probe {  'mediawiki_version':
  url     => '/Special%3AVersion',
  timeout => '15s',
}

varnish::backend { 'default':
  host  => '127.0.0.1',
  port  => '81',
  probe => 'mediawiki_version',
}

notice ("Grabbing varnish_exporter ${varnish_exporter_version}")
staging::file { "varnish_exporter.${varnish_exporter_version}.tar.gz":
  source => $varnish_exporter_url,
}
->staging::extract { "varnish_exporter.${varnish_exporter_version}.tar.gz":
  target  => '/usr/local/bin',
  strip   => 1,
  creates => '/usr/local/bin/prometheus_varnish_exporter',
}

include nubis_discovery

nubis::discovery::service { 'varnish':
  tcp      => 'localhost:6082',
  interval => '15s',
}

systemd::unit_file { 'varnish_exporter.service':
  content => @("EOT")
[Unit]
Description=Prometheus Varnish Exporter
Wants=basic.target
After=basic.target network.target varnish.service

[Service]
Restart=on-failure
RestartSec=10s

ExecStart=/usr/local/bin/prometheus_varnish_exporter

[Install]
WantedBy=multi-user.target

EOT
} ~> service { 'varnish_exporter':
  ensure => 'stopped',
  enable => true,
}
