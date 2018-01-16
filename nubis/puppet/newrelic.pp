include apt

apt::source { 'newrelic':
  comment  => 'This is the New Relic package repository',
  location => 'http://apt.newrelic.com/debian/',
  release  => 'newrelic',
  repos    => 'non-free',
  key      => {
    'id'   => 'B60A3EC9BC013B9C23790EC8B31B29E5548C16BF',
  },
  include  => {
    'deb'  => true,
  },
}

exec { 'newrelic_apt_update':
  command => 'apt-get update',
  cwd     => '/tmp',
  path    => ['/usr/bin'],
  require => Apt::Source['newrelic'],
}

package { 'newrelic-php5':
  ensure  => 'installed',
  require => Exec['newrelic_apt_update'],
}

exec { 'newrelic-install':
  command     => 'newrelic-install install',
  path        => ['/usr/bin', '/bin'],
  environment => ['NR_INSTALL_SILENT=true'],
  require     => Package['newrelic-php5'],
}
