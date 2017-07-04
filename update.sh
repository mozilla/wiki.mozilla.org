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

DEV="wiki-dev.allizom.org"
STAGE="wiki.allizom.org"
PROD="wiki.mozilla.org"
GENERICADM="genericadm.private.phx1.mozilla.com"

# Call the deploy script if necessary and reload Apache
if [ "$HOST" != "$GENERICADM" ]; then
    echo
    echo "ERROR: $HOST != '$GENERICADM'"
    exit 1
fi
if [[ "$CWD" == *"$DEV"* ]]; then
    WEBSITE="$DEV"
    TARGET="genericrhel6-dev"
    NETAPP="/mnt/netapp_dev/$WEBSITE"
elif [[ "$CWD" == *"$STAGE"* ]]; then
    WEBSITE="$STAGE"
    TARGET="genericrhel6-stage"
    NETAPP="/mnt/netapp_stage/$WEBSITE"
elif [[ "$CWD" == *"$PROD"* ]]; then
    WEBSITE="$PROD"
    TARGET="genericrhel6"
    NETAPP="/mnt/netapp/$WEBSITE"
else
    echo "ERROR: Could not match deployment environment"
    exit 1
fi

if ! hash php 2> /dev/null; then
    echo "ERROR: php bindary not found.  Installation cannot continue."
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

# Used because Ubuntu has git 2.13.x
echo
echo "updating submodules in parallel using JOBS=$JOBS"
git submodule update --init --recursive --jobs=$JOBS

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
echo "linking LocalSettings.php into core/LocalSettings.php"
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

echo
echo "install any extensions managed by Composer"
(cd core && php ../tools/composer.phar install --no-dev)

echo
echo "updating any already-installed composer files"
(cd core && php ../tools/composer.phar update --no-dev)

echo
echo "run the localisation cache update so we don't have to check on every page load"
(cd core && php maintenance/rebuildLocalisationCache.php)

echo
echo "run the maintenance/update.php --quick for database migrations"
(cd core && php maintenance/update.php --quick)

echo
echo "deploying $WEBSITE"
if_debug "skipping..."
/data/$TARGET/deploy $WEBSITE
echo
echo "restarting apache gracefully"
issue-multi-command $TARGET service httpd graceful

echo
echo "update.sh script finished"
