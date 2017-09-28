case $::osfamily {
    'RedHat': {
        $makepasswd_package_version     = '5.44.1.15-5.12.amzn1'
        $makepasswd_package_name        = 'expect'
        $package_manager_update_command = '/usr/bin/yum check-update'
        $motd_update_command            = '/usr/sbin/update-motd'
    }
    'Debian', 'Ubuntu': {
        $makepasswd_package_version     = '1.10-9'
        $makepasswd_package_name        = 'makepasswd'
        $package_manager_update_command = '/usr/bin/apt-get update'
        $motd_update_command            = '/bin/run-parts /etc/update-motd.d/ > /var/run/motd.dynamic'
    }
    default: {
        notice("MOTD not supported on ${::osfamily}")
    }
}

