include nubis_storage

nubis::storage { $project_name:
  type  => 'efs',
  owner => 'www-data',
  group => 'www-data',
}
