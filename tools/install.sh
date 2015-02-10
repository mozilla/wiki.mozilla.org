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

# three cheers for parameter expansion!

# this is name of base directory with no path details
CURRENT_DIR=${PWD##*/}
# this is the base directory's parent
PARENT_DIR=${PWD%%/$CURRENT_DIR}
# this is the full current working directory
CURRENT_PWD=`pwd`

# Install of the extensions we get through the manual (git vcs) process
echo "Initializing git submodules recursively..."
git submodule update --init --recursive

# Install of the extensions we get through composer
if [ -e "tools/composer.phar" ]
then
  echo "Composer found, running install..."
  php tools/composer.phar install
else
  echo "Cannot find composer binary. Are you running this from top directory of project?"
  exit
fi

# Symlink the settings file. Doing this here helps keep the core submodule
#+ (and my development work-flow) cleaner
if [ -e "LocalSettings.php" ]
then
  if [ ! -e "core/LocalSettings.php" ]
  then
    echo "LocalSettings.php found, symlinking to core/LocalSettings.php"
    ln -s ${CURRENT_PWD}/LocalSettings.php ${CURRENT_PWD}/core/LocalSettings.php
  else
    echo "Symlink to core/LocalSettings.php already exists. Skipping."
  fi
else
  echo "Cannot find LocalSettings.php. Did you create this file from LocalSettings.php-dist?"
fi

# TODO
# Might wish to move the rewrites from the Apache Vhost file to an htaccess file
#ln -s $(pwd)/htaccess $(pwd)/core/.htaccess

# This font is used by the Sandstone extension and I am symlinking it here
#+ until we find a better way to handle it
if [[ -d "${CURRENT_PWD}/core/skins/common" && -d "${CURRENT_PWD}/assets/fonts" ]]
then
  if [ ! -L "${CURRENT_PWD}/core/skins/common/fonts" ]
  then
    echo "assets/fonts directory exists. Creating symlink to it from core/skins/common..."
    ln -s ${CURRENT_PWD}/assets/fonts ${CURRENT_PWD}/core/skins/common/fonts
  else
    echo "Symlink to assets/fonts already exists. Skipping."
  fi
else
  echo "assets/font directory missing. Cannot create symblink."
fi


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
        ln -s /mnt/netapp_dev/wiki-dev.allizom.org/php_sessions ./
    elif [ $(pwd | grep -c "wiki.allizom.org") == 1 ]; then
        ln -s /mnt/netapp_stage/wiki.allizom.org/images/ ./
        ln -s /mnt/netapp_stage/wiki.allizom.org/Bugzilla_charts/ ./extensions/Bugzilla/
        ln -s /mnt/netapp_stage/wiki.allizom.org/php_sessions ./
    elif [ $(pwd | grep -c "wiki.mozilla.org") == 1 ]; then
        ln -s /mnt/netapp/wiki.mozilla.org/images/ ./
        ln -s /mnt/netapp/wiki.mozilla.org/Bugzilla_charts/ ./extensions/Bugzilla/
        ln -s /mnt/netapp/wiki.mozilla.org/php_sessions ./
    else
        echo "ERROR: Could not determine install path"
        exit 1
    fi
else
  echo "local install"
    # php_sessions only exists in my test environment as we are using memcache for
    #+ this in the production deployments
    if [ -e "${PARENT_DIR}/php_sessions" ]
    then
      echo "${PARENT_DIR}/php_sessions exists."
      if [ ! -L "${CURRENT_PWD}/php_sessions" ]
      then
        echo "Creating symlink to from ${PARENT_DIR}/php_sessions to ${CURRENT_PWD}/php_sessions."
        ln -s ${PARENT_DIR}/php_sessions ${CURRENT_PWD}/php_sessions
      else
        echo "Symlink to ${CURRENT_PWD}/php_sessions already exists. Skipping."
      fi
    else
      echo "${PARENT_DIR}/php_sessions does not exist. Skiping symlink creation."
    fi
    if [ -e "${PARENT_DIR}/images" ]
    then
      echo "${PARENT_DIR}/images exists."
      if [ ! -L "${CURRENT_PWD}/images" ]
      then
        echo "Creating symlink to from ${PARENT_DIR}/images to ${CURRENT_PWD}/images."
        ln -s ${PARENT_DIR}/images ${CURRENT_PWD}/images
      else
        echo "Symlink to ${CURRENT_PWD}/images already exists. Skipping."
      fi
    else
      echo "${PARENT_DIR}/images does not exist. Skiping symlink creation."
    fi
    if [ -e "${PARENT_DIR}/charts" ]
    then
      echo "${PARENT_DIR}/charts exists."
      if [ ! -L "${CURRENT_PWD}/extensions/Bugzilla/charts" ]
      then
        echo "Creating symlink to from ${PARENT_DIR}/charts to ${CURRENT_PWD}/extensions/Bugzilla/charts"
        ln -s ${PARENT_DIR}/charts ${CURRENT_PWD}/extensions/Bugzilla/charts
      else
        echo "Symlink to ${CURRENT_PWD}/extensions/Bugzilla/charts already exists. Skipping."
      fi
    else
      echo "${PARENT_DIR}/charts does not exist. Skiping symlink creation."
    fi

    #chown -R www-data:www-data $(pwd)
    # let's try chaning the group instead
    chgrp -R www-data ${CURRENT_PWD}
fi

# eof
