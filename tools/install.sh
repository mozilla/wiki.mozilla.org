#!/bin/bash
#
# This is a simple istall script to help with final setup.
#
# This stuff will all be included in automation frameworks, therefore this is
#+ really just a placeholder for local and generic cluster deployments.
#

pushd ../
    git submodule update --init --recursive
popd

pushd ../core
    ln -s ../LocalSettings.php ./
#    ln -s ../htaccess ./.htaccess

popd

if [ $(hostname) == 'genericadm.private.phx1.mozilla.com' ]; then
    ln -s update ../
fi

# eof