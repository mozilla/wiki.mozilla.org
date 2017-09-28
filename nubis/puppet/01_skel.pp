# This application specific puppet file is where we do work that is not
#+ already included in other puppet modules.
#
# There are a number of examples in here for installing packages as well
#+ as working with files and templates.
#
# Feel free to remove any of these that you do not need for your project.
#

exec { 'package_manager_update':
  command => $package_manager_update_command,
  returns => [ '0', '100' ],
}

package { 'makepasswd_package':
  ensure  => $makepasswd_package_version,
  name    => $makepasswd_package_name,
  require => Exec['package_manager_update'],
}

file { '/etc/update-motd.d/55-nubis-welcome':
  source => 'puppet:///nubis/files/nubis-welcome', #lint:ignore:puppet_url_without_modules
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

exec { 'motd_update':
  command => $motd_update_command,
  require => File['/etc/update-motd.d/55-nubis-welcome'],
}
