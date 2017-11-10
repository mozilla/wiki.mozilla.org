include nubis_storage

nubis::storage { $project_name:
  type  => 'efs',
  owner => 'www-data',
  group => 'www-data',
}

file { "/usr/local/bin/${project_name}-backup":
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0755',
    source => 'puppet:///nubis/files/backup',
}

cron::daily { "${project_name}-backup":
  command => "/usr/local/bin/${project_name}-backup /data/$project_name",
  # Pick a time between 0-5 hour
  hour => fqdn_rand(6)
  # Pick a random minute
  minute => fqdn_rand(60),
}
