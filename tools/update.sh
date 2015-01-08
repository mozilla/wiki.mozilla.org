#!/bin/sh
#
# This script is used to pull down updates from github
#+ additionally call the deployment scripts if operating on the generic cluster
#
# For legacy reasons this script is symlinked to the project root during install
#+ This can (should) change once we have migrated off of the generic cluster
#+ Ideally this should all take place through Captain-Shove or CI automation
#
# To run this script from the project root directory:
#+ bash update.sh
#

# Grab any changes
git pull

# Pull in any updates to submodules
git submodule update --recursive

# Update any extensions installed through Composer
php tools/composer.phar update

# Run the maintenance script for any database migrations
php core/maintenance/update.php --quick

# Call the deploy script if necessary and reload Apache
if [ $(hostname) == 'genericadm.private.phx1.mozilla.com' ]; then
    if [ $(pwd | grep -c "wiki-dev.allizom.org") == 1 ]; then
        /data/genericrhel6-dev/deploy wiki-dev.allizom.org
        issue-multi-command genericrhel6-dev service httpd graceful
    elif  [ $(pwd | grep -c "wiki.allizom.org") == 1 ]; then
        /data/genericrhel6-stage/deploy wiki.allizom.org
        issue-multi-command genericrhel6-stage service httpd graceful
    elif  [ $(pwd | grep -c "wiki.mozilla.org") == 1 ]; then
        /data/genericrhel6/deploy wiki.mozilla.org
        issue-multi-command genericrhel6 service httpd graceful
    else
        echo "ERROR: Could not match deployment environment"
        exit 1
    fi
else
    service apache2 graceful
fi

# eof
