#!/bin/sh
#
# Download and update channels for Plex
#
# Logs to /var/log/plex-channel-update.log and updates the following channels
# DVBLink   - download master
# Spotify   - download master
# Sub-zero  - download latest release
# Trakttv   - download latest release
#

cd /volume1/Plex/Library/Application\ Support/Plex\ Media\ Server/Plug-ins/
/var/packages/Plex\ Media\ Server/scripts/start-stop-status status stop

logger "Downloading DVBLink Plex Client "
wget https://github.com/cpaton/dvblink-plex-client/archive/master.zip
if [ -f ./master.zip ]; then
    logger "Unzipping DVBLink Plex Client master.zip"
    unzip master.zip
    if [ -d ./Dvblink.bundle-master ]; then
        logger "Removing current DVBLink Plex Client channel directory"
        rm -Rf ./Dvblink.bundle
        logger "Moving updated DVBLink Plex Client channel directory"
        mv ./Dvblink.bundle-master ./Dvblink.bundle
        if [ -d ./Dvblink.bundle ]; then
            logger "Succesfully updated DVBLink Plex Client channel"
        fi
    else
        logger -s "Unzip failed for DVBLink Plex Client "
    fi
else
    logger -s "Downloading failed for DVBLink Plex Client "
fi

wget -O latest-release.zip $(curl -s https://api.github.com/repos/pannal/Sub-Zero.bundle/releases | grep zipball_url | head -n 1 | cut -d '"' -f 4)
if [ -f latest-release.zip ]; then
    rm -Rf ./Sub-Zero.bundle
    unzip latest-release.zip
fi

wget -O latest-release.zip $(curl -s https://api.github.com/repos/trakt/Plex-Trakt-Scrobbler/releases | grep zipball_url | head -n 1 | cut -d '"' -f 4)
if [ -f latest-releaste.zip ]; then
    unzip latest-release.zip
    if [ -d $(ls | grep trakt | head -n 1) ]; then
        rm -Rf ./Trakttv.bundle
        mv $(ls | grep trakt | head -n 1)/Trakttv.bundle ./Trakttv.bundle
        rm -Rf $(ls | grep trakt | head -n 1)
    fi

fi