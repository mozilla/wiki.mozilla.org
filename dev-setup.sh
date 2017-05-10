#!/bin/bash
#
# This script is used to pull down updates
#+ bash update.sh
#

set -e

if [ -z "$BASH_VERSION" ]; then
   echo Run with bash!
   exit 1
fi

DEBUG="${DEBUG:=${CWD}${HOST}}"
CWD=${CWD:=$(pwd)}
HOST=${HOST:=$(hostname)}
JOBS=${JOBS:=$(($(nproc) * 3))}
BRANCH=REL1_27

echo "CWD     = $CWD"
echo "HOST    = $HOST"
echo "JOBS    = $JOBS"

link() {
    link="$1"
    file="$2"

    if [ "$link" = "$file" ]; then
	echo "error: link=$link and file=$file are identical"
	exit 1
    fi

    if [ -L "$link" ]; then
	echo "link=$link exists"
	if [ "$(readlink $link)" = "$file" ]; then
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

link_subdirs() {
    dir="$1"

<<<<<<< HEAD
    for subdir in $dir/*; do
=======
    for $subdir in $dir/*; do
>>>>>>> Set up so skins are submodules
        extname=`basename $subdir`
        echo "  Linking $extname"
        link core/$dir/$extname ../../$dir/$extname
    done
}

if_debug() {
	msg=$1
	if [ "$DEBUG" ]; then
		echo
		echo "DEBUG: $msg"
		exit 1
	fi
}

echo -n "Verifying pre-requisites: ..."
php -r 'if ( function_exists( "imagepng" ) ) { echo " GD"; } else { echo " Install GD extension for PHP"; sleep(30); }'
echo
echo
echo "grabbing any changes via git pull"
git pull

echo
echo "writing the submodule paths to the .git/config file via git submodule init"
git submodule init

# the following command required --init to make extensions/Widgets recurse and checkout smarty/
echo
echo "updating submodules in parallel using JOBS=$JOBS"
time git submodule status | awk '{print $2}' | xargs --max-procs=$JOBS -n1 git submodule update --init --recursive

# switch to this when we can guarantee a git version of 2.8 or greater
# git submodule update --init --recursive --jobs=$JOBS

# LocalSettings.php and extensions is ignored in core so the checkout is still clean.

echo
echo "linking LocalSettings.php into core submodule"
link core/LocalSettings.php ../LocalSettings.php

echo
echo "Update submodules from WMF repositories"
git submodule -q foreach 'git remote -v | grep -q wikimedia.org/ && ( echo $name; git fetch origin; git checkout $branch ) || echo ------- update $name manually' || true

echo
echo "Linking parent vendor"
link core/vendor ../vendor

echo
echo "Linking extensions into subdir so wfLoadExtension can find them"
link_subdirs extensions

echo
echo "Linking skins into subdir so wfLoadSkin can find them"
link_subdirs skins

link core/composer.local.json ../composer.json

# The following link command "dirty" the checkout
echo
<<<<<<< HEAD
echo "linking to assets"
link core/skins/common/assets ../../../assets
=======
echo "linking to fonts submodule"
link core/skins/common/fonts ../../../assets/fonts
>>>>>>> Set up so skins are submodules

if hash php 2> /dev/null; then
   echo
   echo "install any extensions managed by Composer"
   echo "to update, run php tools/composer.phar update prior to deployment"
   ( cd core; php ../tools/composer.phar install --no-dev --prefer-source )

   echo
   echo "run the maintenance/update.php --quick for database migrations"
   (cd core && php maintenance/update.php --quick)
else
    echo "php not installed"
fi

echo
echo "update.sh script finished"
