include nubis_storage

nubis::storage { $project_name:
  type  => 'efs',
  owner => 'www-data',
  group => 'www-data',
}

### puppet-nubis-storage

# Link to our mountpoints
file { '/var/www/${project_name}':
  ensure => 'directory',
  force  => true,
}
file { '/var/www/${project_name}/images':
  ensure => 'link',
  force  => true,
  target => "/data/${project_name}/images",
}
file { '/var/www/${project_name}/php_sessions':
  ensure => 'link',
  force  => true,
  target => "/data/${project_name}/php_sessions",
}
