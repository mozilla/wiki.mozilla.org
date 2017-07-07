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

if ! hash php 2> /dev/null; then
    echo "ERROR: php bindary not found.  Installation cannot continue."
    exit 1
fi

corepatch=`ls patches/core/*.patch 2>/dev/null`
if [ -z "$corepatch" ] ; then
    echo "Don't forget the core patch from https://phabricator.wikimedia.org/T167937"
    echo "It should be a file ending with .patch in the patches/core sub directory."
    exit 1
fi

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
echo "make sure submodule repos are in sync with upstream via git submodule sync"
git submodule sync

echo
echo "writing the submodule paths to the .git/config file via git submodule init"
git submodule init

# the following command required --init to make extensions/Widgets recurse and checkout smarty/
echo
echo "updating submodules in parallel using JOBS=$JOBS"
time git submodule status | awk '{print $2}' | xargs --max-procs=$JOBS -n1 git submodule update --init --recursive 2> /dev/null

# Later git (> 2.8) can use this instead 
#git submodule update --init --recursive --jobs=$JOBS

echo
echo "linking extensions"
for ext in `find extensions -maxdepth 1 -mindepth 1 -type d`; do
    link core/$ext ../../$ext
done

echo
echo "linking skins"
for skin in `find skins -maxdepth 1 -mindepth 1 -type d`; do
    link core/$skin ../../$skin
done

echo "setting up cache directory"
mkdir -p /var/tmp/wikimo-cache
chown -R www-data /var/tmp/wikimo-cache

echo "Setting permissions on Widgets"
chown -R www-data extensions/Widgets/compiled_templates

patches=`cd patches; find . -type f -name "*.patch"`
if [ -n "$patches" ]; then
    echo
    echo "applying local patches"
    for patch in ; do
        patchdir=`dirname $patch`
        pwd=`pwd`
        cd $patchdir && echo in $patchdir
        git am $pwd/$patch
        cd $pwd
    done
fi

# All the following link commands are in the default .gitignore
echo
echo "linking LocalSettings.php into core submodule"
link core/LocalSettings.php ../LocalSettings.php

echo
echo "linking composer.json to core/composer.json.local"
link core/composer.local.json ../composer.json

echo
echo "linking vendor to core/vendor"
mkdir -p vendor
link core/vendor ../vendor

echo
echo "linking images"
link images $NETAPP/images

echo
echo "linking php sessions"
link php_sessions $NETAPP/php_sessions

echo
echo "linking to Bugzilla charts on netapp filer"
link extensions/Bugzilla/charts $NETAPP/Bugzilla_charts/

(cd core && php ../tools/composer.phar install --no-dev)

echo
echo "updating any already-installed composer files"
(cd core && php ../tools/composer.phar update --no-dev)

echo
echo "run the localisation cache update so we don't have to check on every page load"
(cd core && php maintenance/rebuildLocalisationCache.php)

echo
echo "restarting apache gracefully"
service apache2 graceful

echo
echo "update.sh script finished"
