#!/bin/bash
#
# This script is used to sync assets from production back to {dev|stage|test}
#+ There is currently no method for this operation outside of core IT
#
# NOTE: This script can take quite some time to complete:
#+ $ time bash tools/sync_assets.sh
#+ $ 27m 23.035s
#
# To run this script from the project root directory:
#+ bash tools/sync_assets.sh
#

# This function will sync a database from production to the current instance
#+ based on the directory you are sitting in ($(pwd))
sync_database (){
    # Grab the MySql settings for production
    #PROD_FILE='/data/genericrhel6/src/wiki.mozilla.org/secrets.php'
    PROD_FILE='/data/genericrhel6/src/wiki.mozilla.org/wiki/LocalSettings.php'
    if [ ! -f $PROD_FILE ]; then
        echo "ERROR: Could not find production settings file"
        exit 1
    fi
    PROD_DBSLAVE='generic-ro-zeus.db.phx1.mozilla.com'
# Comment out new way until the git deployment is running in prod, then
#+ uncomment these and delete the current ones (ask jd any questions)
#+ Also the PROD_FILE variable above
#    PROD_DBSERVER=$(cat $PROD_FILE | grep wgDBserver | cut -d "'" -f 2)
#    PROD_DBNAME=$(cat $PROD_FILE | grep wgDBname | cut -d "'" -f 2)
#    PROD_DBUSER=$(cat $PROD_FILE | grep wgDBuser | cut -d "'" -f 2)
#    PROD_DBPASSWORD=$(cat $PROD_FILE | grep wgDBpassword | cut -d "'" -f 2)
    PROD_DBSERVER=$(cat $PROD_FILE | grep \'host\' | cut -d "\"" -f 2)
    PROD_DBNAME=$(cat $PROD_FILE | grep \'dbname\' | cut -d "\"" -f 2)
    PROD_DBUSER=$(cat $PROD_FILE | grep \'user\' | grep -v Group | cut -d "\"" -f 2)
    PROD_DBPASSWORD=$(cat $PROD_FILE | grep \'password\' | cut -d "\"" -f 2)
    echo -e "[client]\npassword=$PROD_DBPASSWORD" > .PROD_DBPASSWORD

    # Grab MySql settings for this instance {dev|stage}
    INSTANCE_FILE="$(pwd)/secrets.php"
    if [ ! -f $INSTANCE_FILE ]; then
        echo "ERROR: Could not find instance settings file"
        exit 1
    fi
    DBSERVER=$(cat $INSTANCE_FILE | grep wgDBserver | cut -d "'" -f 2)
    DBNAME=$(cat $INSTANCE_FILE | grep wgDBname | cut -d "'" -f 2)
    DBUSER=$(cat $INSTANCE_FILE | grep wgDBuser | cut -d "'" -f 2)
    DBPASSWORD=$(cat $INSTANCE_FILE | grep wgDBpassword | cut -d "'" -f 2)
    echo -e "[client]\npassword=$DBPASSWORD" > .DBPASSWORD

    # Dump the production database and load it into the instance database
    echo "Syncing MySql database..."
    DUMP_FILE="$PROD_DBNAME_$(date +%Y%m%d_%T).sql"
    mysqldump --defaults-file=.PROD_DBPASSWORD --opt --host=$PROD_DBSLAVE --user=$PROD_DBUSER $PROD_DBNAME |\
    mysql --defaults-file=.DBPASSWORD -C --host=$DBSERVER --user=$DBUSER $DBNAME

    # Clean up
    rm -f .PROD_DBPASSWORD .DBPASSWORD
}

# This currently works on genericadm only (Sorry)
if [ $(hostname) == 'genericadm.private.phx1.mozilla.com' ]; then
    # Sync the images directory
    #+ Sync the Bugzilla extension Charts directory
    #+ Sync the database
    if [ $(pwd | grep -c "wiki-dev.allizom.org") == 1 ]; then
        echo "Syncing images directory..."
        rsync -avz /mnt/netapp/wiki.mozilla.org/images/ /mnt/netapp_dev/wiki-dev.allizom.org/images/
        echo "Syncing Bugzilla charts directory..."
        rsync -avz /mnt/netapp/wiki.mozilla.org/Bugzilla_charts/ /mnt/netapp_dev/wiki-dev.allizom.org/Bugzilla_charts/
        sync_database
    elif [ $(pwd | grep -c "wiki.allizom.org") == 1 ]; then
        rsync -avz /mnt/netapp/wiki.mozilla.org/images/ /mnt/netapp_stage/wiki.allizom.org/images/
        rsync -avz /mnt/netapp/wiki.mozilla.org/Bugzilla_charts/ /mnt/netapp_stage/wiki.allizom.org/Bugzilla_charts/
        sync_database
    elif [ $(pwd | grep -c "wiki.mozilla.org") == 1 ]; then
        echo "Not syncing assets as this is prod."
        exit 1
    else
        echo "ERROR: Could not match deployment environment"
        exit 1
    fi
else
    echo "This probably will not work here."
    echo "Ping jd or ckoehler in #wiki on irc.mozilla.org for assistance." 
fi

# eof