#!/bin/bash
#
# This is a simple install script to help with initial setup.
#
# This stuff will (should) be included in automation frameworks, therefore this
#+ is really just a placeholder for testing and generic cluster deployments.
#
# One thing this script does not do is gather the static assets.
#+ These consist of a copy of the production database and a copy of the images
#+ directory as well as the Bugzilla charts directory.
#
# In my test environment I have created a directory structure that looks like:
#+ /data/www
#+          /charts    <- Rsync copy of data from production
#+          /images    <- Rsync copy of data from production
#+          /php_sessions    <- Empty directory
#+          /wiki-dev.allizom.org    <- Git clone (this repository) here
#+ The '/data/www' bit is not important, but the structure inside is if you want
#+ this script to "just work" (create the symlinks correctly).
#
# To run this script from the project root directory:
#+ bash tools/install.sh
#

# Install of the extensions we get through the manual (git vcs) process
git submodule update --init --recursive

# Install of the extensions we get through composer
php tools/composer.phar install

# Symlink the settings file. Doing this here helps keep the core submodule
#+ (and my development work-flow) cleaner
ln -s $(pwd)/LocalSettings.php $(pwd)/core

# TODO
# Might wish to move the rewrites from the Apache Vhost file to an htaccess file
#ln -s $(pwd)/htaccess $(pwd)/core/.htaccess

# This font is used by the Sandstone extension and I am symlinking it here
#+ until we find a better way to handle it
ln -s $(pwd)/assets/fonts $(pwd)/core/skins/common/fonts

# Set up symlinks for static assets.
#
# This is on the Netapp (nfs) on core infra (phx1).
#
# In my (jd) test environment I have them one level up, we will likely want to
#+ change this when we determine a good way to distribute these for testing
#+ environments
#
if [ $(hostname) == 'genericadm.private.phx1.mozilla.com' ]; then
    ln -s tools/update.sh ./
    if [ $(pwd | grep -c "wiki-dev.allizom.org") == 1 ]; then
        ln -s /mnt/netapp_dev/wiki-dev.allizom.org/images/ ./
        ln -s /mnt/netapp_dev/wiki-dev.allizom.org/Bugzilla_charts/ ./extensions/Bugzilla/
    elif [ $(pwd | grep -c "wiki.allizom.org") == 1 ]; then
        ln -s /mnt/netapp_stage/wiki.allizom.org/images/ ./
        ln -s /mnt/netapp_stage/wiki.allizom.org/Bugzilla_charts/ ./extensions/Bugzilla/
    elif [ $(pwd | grep -c "wiki.mozilla.org") == 1 ]; then
        ln -s /mnt/netapp_dev/wiki.mozilla.org/images/ ./
        ln -s /mnt/netapp_dev/wiki.mozilla.org/Bugzilla_charts/ ./extensions/Bugzilla/
    else
        echo "ERROR: Could not determine install path"
        exit 1
    fi
else
    # php_sessions only exists in my test environment as we are using memcache for
    #+ this in the production deployments
    ln -s $(pwd)/../php_sessions $(pwd)/php_sessions
    ln -s $(pwd)/../images $(pwd)/images
    ln -s $(pwd)/../charts $(pwd)/extensions/Bugzilla/charts
    chown -R www-data:www-data $(pwd)
fi

# eof