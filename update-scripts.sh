#!/bin/sh
#
# Update script for updating the checkout from github
#
logger "Synology Scripts - Updating synology scripts from github"
logger "Synology Scripts - Go to upper directory and download latest master"
cd /volume1/applications
rm ./master.zip
wget https://github.com/geertbongers/synology-scripts/archive/master.zip
if [ -f "./master.zip" ]; then
    logger "Synology Scripts - Unzipping master zip"
    rm -Rf ./synology-scripts-master
    unzip ./master.zip
    if [ -d "./synology-scripts-master" ]; then
        logger "Synology Scripts - Downloading master zip"
        rm -Rf ./synology-scripts
        mv ./synology-scripts-master ./synology-scripts
    else
        logger -p local0.err "Synology Scripts - Unzipping failed download master.zip"
    fi
    rm ./master.zip
else
    logger -p local0.err "Synology Scripts - Failed download master.zip"
fi