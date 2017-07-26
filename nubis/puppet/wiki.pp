# Install mysql client libraries
include mysql::client

package { "php5-mysql":
  ensure => 'latest'
}

package { 'php5-xcache':
  ensure => 'latest'
}

package { 'graphviz':
  ensure => 'latest'
}

package { 'php5-memcache':
  ensure => 'latest'
}

package { 'php5-intl':
  ensure => 'latest'
}

package { 'php5-gd':
  ensure => 'latest'
}

package { 'pandoc':
  ensure => 'latest'
}

package { 'memcached':
  ensure => 'latest'
}

package { 'librsvg2-bin':
  ensure => 'latest'
}

package { 'imagemagick':
  ensure => 'latest'
}

# Superceded by apache::mod:php we suspect
#package { 'libapache2-mod-php5':
#  ensure => 'latest';
#}


# Generate some random secrets for mediawiki on boot
file { '/etc/nubis.d/wiki-secrets':
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0755',
    source => 'puppet:///nubis/files/wiki-onboot',
}
