<?php
    $ENVIRONMENT            = getenv('ENVIRONMENT', 'stage');

    # database config
    $SECRETS_wgDBserver     = getenv('MYSQL_HOST');
    $SECRETS_wgDBname       = getenv('MYSQL_DATABASE', 'wiki');
    $SECRETS_wgDBuser       = getenv('MYSQL_USER', 'admin');
    $SECRETS_wgDBpassword   = getenv('MYSQL_PASSWORD');

    # Memcached
    $SECRETS_wgMemCachedServers = getenv('MEMCACHED_HOST');

    # Configs
    $SECRETS_wgUploadDirectory = getenv('WG_UPLOADDIR', '/var/www/html/images');

?>
