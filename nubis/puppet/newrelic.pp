apt::source { 'newrelic':
  comment  => 'This is the New Relic package repository',
  location => 'http://apt.newrelic.com/debian/',
  release  => 'non-free',
  repos    => 'newrelic non-free',
  key      => {
    'id'   => 'B60A3EC9BC013B9C23790EC8B31B29E5548C16BF',
  },
  include  => {
    'deb'  => true,
  },
}

package { 'newrelic-php5':
  ensure  => 'installed',
  require => Apt::Source['newrelic'],
}

exec { 'newrelic-install':
  command     => 'newrelic-install install',
  path        => ['/usr/bin', '/bin'],
  environment => ['NR_INSTALL_SILENT=true'],
  require     => Package['newrelic-php5'],
}