# This needs to be here in order to pass environment variables from
# the container -> apache. After we get these values will source the file
# in /etc/apache2/envvars

export SITE_URL="${SITE_URL}"
export MEMCACHED_HOST="${MEMCACHED_HOST}"
export MEMCACHED_PORT="${MEMCACHED_PORT}"
