#!/bin/bash
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

set -e

DEBUG="${DEBUG:=${CWD}${HOST}}"
CWD=${CWD:=$(pwd)}
HOST=${HOST:=$(hostname)}
JOBS=${JOBS:=$(($(nproc) * 3))}

WEBSITE="wiki.mozilla.org"
NETAPP="/mnt/netapp/$WEBSITE"

echo "CWD     = $CWD"
echo "HOST    = $HOST"
echo "JOBS    = $JOBS"
echo "WEBSITE = $WEBSITE"
echo "TARGET  = $TARGET"
echo "NETAPP  = $NETAPP"

link() {
    link="$1"
    file="$2"

    if [ "$link" == "$file" ]; then
        echo "error: link=$link and file=$file are identical"
        exit 1
    fi

    if [ -L "$link" ]; then
        echo "link=$link exists"
        if [ "$(readlink $link)" == "$file" ]; then
            echo "[exists] $link -> $file"
        else
            echo "error: link=$link exists but points here=$(readlink $link) instead of file=$file"
            exit 1
        fi
    elif [ -f "$link" ]; then
        echo "error: link=$link exists but is not a symlink"
    else
        (cd $(dirname $link) && ln -s $file $(basename $link))
        echo "[create] $link -> $file"
    fi
}

if_debug() {
    msg=$1
    if [ "$DEBUG" ]; then
        echo
        echo "DEBUG: $msg"
        exit 1
    fi
}

echo
echo "grabbing any changes via git pull"
git pull

echo
echo "writing the submodule paths to the .git/config file via git submodule init"
git submodule init

# the following command required --init to make extensions/Widgets recurse and checkout smarty/
echo
echo "updating submodules in parallel using JOBS=$JOBS"
time git submodule status | awk '{print $2}' | xargs --max-procs=$JOBS -n1 git submodule update --init --recursive 2> /dev/null

echo
echo "updating nested submodule"
(cd extensions/Widgets && time git submodule update --init --recursive)

# switch to this when we can guarantee a git version of 2.8 or greater
# git submodule update --init --recursive --jobs=$JOBS

# The following link commands "dirty" the checkout

echo
echo "linking LocalSettings.php into core submodule"
link core/LocalSettings.php ../LocalSettings.php

echo
echo "linking to fonts submodule"
mkdir -p core/skins/common
link core/skins/common/fonts ../../../assets/fonts

echo
echo "linking images"
link images $NETAPP/images

echo
echo "linking php sessions"
link php_sessions $NETAPP/php_sessions

echo
echo "linking to Bugzilla charts on netapp filer"
link extensions/Bugzilla/Bugzilla_charts $NETAPP/Bugzilla_charts/

if hash php 2> /dev/null; then
    echo "install any extensions managed by Composer"
    echo "to update, run php tools/composer.phar update prior to deployment"
    php tools/composer.phar install

    echo
    echo "run the maintenance/update.php --quick for database migrations"
    (cd core && php maintenance/update.php --quick)
else
    echo "php not installed"
fi

echo
echo "restarting apache gracefully"
service apache2 graceful

echo
echo "update.sh script finished"
