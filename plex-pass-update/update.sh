RELEASE="x86"
RELEASE_TITLE="Intel"
PKGEXT=".spk"
URL_LOGIN=https://plex.tv/users/sign_in
URL_DOWNLOAD=https://plex.tv/downloads?channel=plexpass
DOWNLOADDIR=/volume1/applications/synology-scripts-data/plex-pass-update/releases
mkdir -p /volume1/applications/synology-scripts-data/plex-pass-update/releases
SKIP_DOWNLOAD="no"

# Useful functions
rawurlencode() {
	echo "$1"
}

keypair() {
	local key="$( rawurlencode "$1" )"
	local val="$( rawurlencode "$2" )"

	echo "${key}=${val}"
}

# Setup an exit handler so we cleanup
#function cleanup {
#	rm /tmp/kaka 2>/dev/null >/dev/null
#	rm /tmp/postdata 2>/dev/null >/dev/null
#	rm /tmp/raw 2>/dev/null >/dev/null
#}
#trap cleanup EXIT

echo -n "Authenticating..."
# Clean old session
rm /tmp/kaka 2>/dev/null

# Get initial seed we need to authenticate
SEED=$(wget --save-cookies /tmp/kaka --keep-session-cookies ${URL_LOGIN} -O - 2>/dev/null | grep 'name="authenticity_token"' | sed 's/.*value=.\([^"]*\).*/\1/')
if [ $? -ne 0 -o "${SEED}" == "" ]; then
    echo "Error: Unable to obtain authentication token, page changed?"
    exit 1
fi

# Build post data
echo -ne  >/tmp/postdata  "$(keypair "utf8" "&#x2713;" )"
echo -ne >>/tmp/postdata "&$(keypair "authenticity_token" "${SEED}" )"
echo -ne >>/tmp/postdata "&$(keypair "user[login]" "${EMAIL}" )"
echo -ne >>/tmp/postdata "&$(keypair "user[password]" "${PASS}" )"
echo -ne >>/tmp/postdata "&$(keypair "user[remember_me]" "0" )"
echo -ne >>/tmp/postdata "&$(keypair "commit" "Sign in" )"

# Authenticate
wget --load-cookies /tmp/kaka --save-cookies /tmp/kaka --keep-session-cookies "${URL_LOGIN}" --post-file=/tmp/postdata -O /tmp/raw 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Error: Unable to authenticate"
    exit 1
fi
# Delete authentication data ... Bad idea to let that stick around
rm /tmp/postdata

# Provide some details to the end user
if [ "$(cat /tmp/raw | grep 'Sign In</title')" != "" ]; then
    echo "Error: Username and/or password incorrect"
    exit 1
fi
echo "OK"

# Extract the URL for our release
echo -n "Finding download URL for ${RELEASE}..."

DOWNLOAD=$(wget --load-cookies /tmp/kaka --save-cookies /tmp/kaka --keep-session-cookies "${URL_DOWNLOAD}" -O - 2>/dev/null | grep "${PKGEXT}" | grep -m 1 "${RELEASE}" | sed "s/.*href=\"\([^\"]*\\${PKGEXT}\)\"[^>]*>${RELEASE_TITLE}.*/\1/" )
echo -e "OK"
echo "${DOWNLOAD}"

if [ "${DOWNLOAD}" == "" ]; then
	echo "Sorry, page layout must have changed, I'm unable to retrieve the URL needed for download"
	exit 3
fi

FILENAME="$(basename 2>/dev/null ${DOWNLOAD})"
if [ $? -ne 0 ]; then
	echo "Failed to parse HTML, download cancelled."
	exit 3
fi
VERSION=$(echo "${FILENAME}" | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,6}-[a-z0-9]{1,9}')

if [ -f "${DOWNLOADDIR}/${FILENAME}" -a "${FORCE}" != "yes" ]; then
	echo "File already exists, won't download."
	cp "${DOWNLOADDIR}/${FILENAME}" "/volume1/web/sspks/packages/plex_bromolow_${VERSION}.spk"
	cp /volume1/applications/synology-scripts/plex-pass-update/plex.nfo /volume1/applications/synology-scripts/plex-pass-update/plex-new.nfo
	echo "version=\"${VERSION}\"" >> /volume1/applications/synology-scripts/plex-pass-update/plex-new.nfo
	mv /volume1/applications/synology-scripts/plex-pass-update/plex-new.nfo /volume1/web/sspks/packages/plex_bromolow_${VERSION}.nfo
	cp /volume1/applications/synology-scripts/plex-pass-update/plex_thumb_72.png /volume1/web/sspks/packages/plex_bromolow_${VERSION}_thumb_72.png
	cp /volume1/applications/synology-scripts/plex-pass-update/plex_thumb_120.png /volume1/web/sspks/packages/plex_bromolow_${VERSION}_thumb_120.png
	cp /volume1/applications/synology-scripts/plex-pass-update/plex_thumb_72.png /volume1/web/sspks/packages/default_package_icon_72.png
	cp /volume1/applications/synology-scripts/plex-pass-update/plex_thumb_120.png /volume1/web/sspks/packages/default_package_icon_120.png
	echo "OK"
	SKIP_DOWNLOAD="yes"
fi

if [ "${SKIP_DOWNLOAD}" == "no" ]; then
	if [ -f "${DOWNLOADDIR}/${FILENAME}" ]; then
		echo "Note! File exists, but asked to overwrite with new copy"
	fi

	echo -ne "Downloading release \"${FILENAME}\"..."
	ERROR=$(wget --load-cookies /tmp/kaka --save-cookies /tmp/kaka --keep-session-cookies "${DOWNLOAD}" -O "${DOWNLOADDIR}/${FILENAME}" 2>&1)
	CODE=$?
	if [ ${CODE} -ne 0 ]; then
		echo -e "\n  !! Download failed with code ${CODE}, \"${ERROR}\""
		exit ${CODE}
	fi
	echo "OK"
fi

# cd /volume1/web/sspks/packages
# extract version from PlexMediaServer-0.9.14.4.1556-a10e3c2-x86.spk
# echo 'PlexMediaServer-0.9.14.4.1556-a10e3c2-x86.spk' | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,6}-[a-z0-9]{1,9}'
# rename to plex_bromolow_9.14-4.spk