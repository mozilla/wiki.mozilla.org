#!/bin/bash
#
# This is a simple istall script to help with initial setup.
#
# This stuff will (should) be included in automation frameworks, therefore this is
#+ really just a placeholder for local and generic cluster deployments.
#
# To run this script from the project root directory:
#+ bash tools/install.sh

# Install of the extensions we get through the manual (git vcs) process
git submodule update --init --recursive

# Install of the extensions we get through composer
php tools/composer.phar install

# Symlink the settings file. Doing this here helps keep the core submodule (and my development workflow) cleaner
pushd core
    ln -s ../LocalSettings.php ./
#    ln -s ../htaccess ./.htaccess
popd

# If this is on core infra in phx1 set up the netapp (nfs) mount points and update script
if [ $(hostname) == 'genericadm.private.phx1.mozilla.com' ]; then
    ln -s tools/update ./
    ln -s /mnt/netapp_dev/wiki-dev.allizom.org/images/ ./
    ln -s /mnt/netapp_dev/wiki-dev.allizom.org/Bugzilla_charts/ ./extensions/Bugzilla/
fi

# eof