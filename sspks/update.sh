cd /volume1/web
wget https://github.com/geertbongers/sspks/archive/plexconnect.zip
unzip plexconnect.zip
rm -Rf sspks-plexconnect/packages/*
cp sspks/packages/* sspks-plexconnect/packages
rm -Rf sspks
mv sspks-plexconnect/ sspks
rm plexconnect.zip
