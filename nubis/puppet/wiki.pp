# Install mysql client libraries
include mysql::client

package { 'php-mysql':
  ensure => 'latest'
}

package { 'php-mbstring':
  ensure => 'latest'
}

package { 'graphviz':
  ensure => 'latest'
}

package { 'php-memcache':
  ensure => 'latest'
}

package { 'php-intl':
  ensure => 'latest'
}

package { 'php-gd':
  ensure => 'latest'
}

package { 'php-mail':
  ensure => 'latest'
}

package { 'pandoc':
  ensure => 'latest'
}

package { 'librsvg2-bin':
  ensure => 'latest'
}

package { 'imagemagick':
  ensure => 'latest'
}

package { 'git':
  ensure => 'latest'
}

# For backups to S3
package { 'awscli':
  ensure => 'latest'
}

# Generate some random secrets for mediawiki on boot and if necessary migrate the DB
file { '/etc/nubis.d/wiki-onboot':
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0755',
    source => 'puppet:///nubis/files/wiki-onboot',
}

# Set up cache directory
file { '/var/tmp/wikimo-cache':
    ensure => directory,
    owner  => www-data,
    group  => www-data,
    mode   => '0750',
}

# Log
file { '/var/log/wiki.log':
    ensure => file,
    owner  => www-data,
    group  => www-data,
    mode   => '0750',
}

# Set permissions for Widgets compiled templates (XXX: Could it be precompiled somehow?)
file { "/var/www/${project_name}/core/extensions/Widgets/compiled_templates":
    ensure  => directory,
    owner   => www-data,
    group   => www-data,
    mode    => '0750',
    require => Exec['mv_extensions'],
}

# Add robots.txt to document root
file { "/var/www/${project_name}/core/robots.txt":
  ensure => file,
  owner  => www-data,
  group  => www-data,
  source => "puppet:///nubis/files/robots.txt",
}

# Link files that aren't in the core repo to where they need to be
file { "/var/www/${project_name}/core/LocalSettings.php":
    ensure => 'link',
    target => "/var/www/${project_name}/LocalSettings.php",
}

file { "/var/www/${project_name}/core/composer.local.json":
    ensure => 'link',
    target => "/var/www/${project_name}/composer.json",
}

file { "/var/www/${project_name}/core/contribute.json":
    ensure => 'link',
    target => "/var/www/${project_name}/contribute.json",
}

file { "/var/www/${project_name}/vendor":
    ensure => 'link',
    target => "/var/www/${project_name}/core/vendor",
}

exec { 'mv_extensions':
    provider => 'shell',
    command  => 'mv extensions/* core/extensions/',
    cwd      => "/var/www/${project_name}",
}
exec { 'mv_skins':
    provider => 'shell',
    command  => 'mv skins/* core/skins/',
    cwd      => "/var/www/${project_name}",
}

# Links to EFS mount dirs
file { "/var/www/${project_name}/images":
    ensure => 'link',
    target => "/data/${project_name}/images",
}
file { "/var/www/${project_name}/php_sessions":
    ensure => 'link',
    target => "/data/${project_name}/php_sessions",
}

file { "/var/www/${project_name}/core/extensions/Bugzilla/charts":
    ensure => 'link',
    target => "/data/${project_name}/Bugzilla_charts",
}

## Install PHP composer extensions
exec { 'composer':
    command     => 'php ../tools/composer.phar install --no-dev --verbose',
    cwd         => "/var/www/${project_name}/core",
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    environment => [
        'HOME=/tmp',
    ],
    require     => [
      Exec['mv_extensions'],
      File["/var/www/${project_name}/core/composer.local.json"],
      File["/var/www/${project_name}/vendor"],
      Class['apache::mod::php'],
    ],
}

# Hot/Monkey Patch MWDebug.php to not spew errors
file { '/tmp/MWDebug.php.patch':
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0755',
    source => 'puppet:///nubis/files/MWDebug.php.patch',
}
exec { 'debug_patch':
    command => '/usr/bin/patch MWDebug.php /tmp/MWDebug.php.patch',
    cwd     => "/var/www/${project_name}/core/includes/debug",
    require => File['/tmp/MWDebug.php.patch'],
}

