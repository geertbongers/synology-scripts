#!/bin/sh
#
# Update script for updating the checkout from github
#
logger "Synology Scripts - Updating synology scripts from github"
logger "Synology Scripts - Go to upper directory and download latest master"
cd .. && wget https://github.com/geertbongers/synology-scripts/archive/master.zip
if ls ./master.zip > /dev/null; then
    logger "Synology Scripts - Unzipping master zip"
    unzip master.zip
    if ls ./synology-scripts-master > /dev/null; then
        logger "Synology Scripts - Downloading master zip"
    else
        logger -p local0.err "Synology Scripts - Unzipping failed download master.zip"
        rm master.zip
    fi
else
    logger -p local0.err "Synology Scripts - Failed download master.zip"
fi