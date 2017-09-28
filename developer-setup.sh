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

    for subdir in $dir/*; do
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
echo "Update submodules from WMF repositories"
git submodule -q foreach 'git remote -v | grep -q wikimedia.org/ && ( echo $name; git fetch origin; git checkout $branch ) || echo ------- update $name manually' || true

echo
echo "linking LocalSettings.php into core submodule"
link core/LocalSettings.php ../LocalSettings.php

echo
echo "Linking parent vendor"
link core/vendor ../vendor

echo
echo "Linking extensions into subdir so wfLoadExtension can find them"
link_subdirs extensions

echo
echo "Linking skins into subdir so wfLoadSkin can find them"
link_subdirs skins

echo
echo "Linking composer.json into composer.local.json fro mediawiki"
link core/composer.local.json ../composer.json

# The following link command "dirty" the checkout
echo
echo "linking to assets"
link core/skins/common/assets ../../../assets

if hash php 2> /dev/null; then
   echo
   echo "install any extensions managed by Composer"
   echo "to update, run php tools/composer.phar update prior to deployment"
   ( cd core; php ../tools/composer.phar install --no-dev --prefer-source )

   echo
   echo "run the maintenance/update.php --quick for database migrations"
   (cd core && php maintenance/update.php --quick)

   echo
   echo "Update the localisation cache"
   (cd core && php maintenance/rebuildLocalisationCache.php)
else
    echo "php not installed"
fi

if hash apt 2> /dev/null; then
    echo
    echo "installing utilites that mediawiki needs, requires sudo"
    sudo apt install librsvg2-bin graphviz php5-intl php5-memcache php5-gd memcached imagemagick pandoc
fi

if [ ! -d extensions/Widgets ]; then
    echo Please execute this in the root of the checkout!
    exit
fi

if [ ! -d extensions/Widgets/compiled_templates ]; then
    mkdir extensions/Widgets/compiled_templates
fi

chmod -R a+w extension/Widgets/compiled_templates

echo
echo "update.sh script finished"
