wget https://github.com/bwynants/sspks/archive/plexconnect.zip
unzip plexconnect.zip
rm -Rf sspks-plexconnect/packages
mv sspks-plexconnect/ sspks
mv sspks/packages sspks-plexconnect/packages
rm plexconnect.zip
