URL_LOGIN=https://plex.tv/users/sign_in
URL_DOWNLOAD=https://plex.tv/downloads?channel=plexpass

# Useful functions
rawurlencode() {
	local string="${1}"
	local strlen=${#string}
	local encoded=""

	for (( pos=0 ; pos<strlen ; pos++ )); do
		c=${string:$pos:1}
		case "$c" in
		[-_.~a-zA-Z0-9] ) o="${c}" ;;
		* )               printf -v o '%%%02x' "'$c"
	esac
	encoded+="${o}"
	done
	echo "${encoded}"
}

keypair() {
	local key="$( rawurlencode "$1" )"
	local val="$( rawurlencode "$2" )"

	echo "${key}=${val}"
}

# Setup an exit handler so we cleanup
function cleanup {
	rm /tmp/kaka 2>/dev/null >/dev/null
	rm /tmp/postdata 2>/dev/null >/dev/null
	rm /tmp/raw 2>/dev/null >/dev/null
}
trap cleanup EXIT

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

DOWNLOAD=$(wget --load-cookies /tmp/kaka --save-cookies /tmp/kaka --keep-session-cookies "${URL_DOWNLOAD}" -O - 2>/dev/null | grep "${PKGEXT}" | grep -m 1 "${RELEASE}" | sed "s/.*href=\"\([^\"]*\\${PKGEXT}\)\"[^>]*>${RELEASE}.*/\1/" )
echo -e "OK"

if [ "${DOWNLOAD}" == "" ]; then
	echo "Sorry, page layout must have changed, I'm unable to retrieve the URL needed for download"
	exit 3
fi

FILENAME="$(basename 2>/dev/null ${DOWNLOAD})"
if [ $? -ne 0 ]; then
	echo "Failed to parse HTML, download cancelled."
	exit 3
fi

if [ -f "${DOWNLOADDIR}/${FILENAME}" -a "${FORCE}" != "yes" ]; then
	echo "File already exists, won't download."
	if [ "${AUTOINSTALL}" != "yes" ]; then
		exit 2
	fi
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

cd /volume1/web/sspks/packages
wget https://plex.tv/downloads?channel=plexpass