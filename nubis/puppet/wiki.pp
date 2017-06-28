# Install mysql client libraries
include mysql::client

package { "php5-mysql":
  ensure => '5.5.9+dfsg-1ubuntu4.21'
}

package { 'php5-xcache':
  ensure => '3.1.0-2'
}

package { 'graphviz':
  ensure => '2.36.0-0ubuntu3.2'
}

package { 'php5-memcache':
  ensure => '3.0.8-4build1'
}

package { 'php5-intl':
  ensure => '5.5.9+dfsg-1ubuntu4.21'
}

package { 'php5-gd':
  ensure => '5.5.9+dfsg-1ubuntu4.21'
}

package { 'pandoc':
  ensure => '1.12.2.1-1build2'
}

package { 'memcached':
  ensure => '1.4.14-0ubuntu9.1'
}

package { 'librsvg2-bin':
  ensure => '2.40.2-1'
}

package { 'imagemagick':
  ensure => '8:6.7.7.10-6ubuntu3.7'
}
