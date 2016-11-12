VERSION=${1}

if [ -z "${VERSION}" ];
then
    echo "Usage: ${0} <version>"
    exit 1
fi

REPO='nas-backup'
FILE="v${VERSION}.tar.gz"
DIST_DIR='./dist'
CURRENT_LINK='current'

DOWNLOAD_URL="https://github.com/ebridges/${REPO}/archive/${FILE}"

cd ${DIST_DIR}
echo "[INFO] Downloading archive for version [${VERSION}]."
wget ${DOWNLOAD_URL}
echo "[INFO] Extracting archive [${FILE}]."
tar xzf ${FILE}
echo "[INFO] Disposing downloaded archive."
rm -f ${FILE}
PRIOR=`stat -c '%N' ${CURRENT_LINK}`
echo "[INFO] Removing link to prior version [${PRIOR}]."
rm ${CURRENT_LINK}
echo "[INFO] Linking to new version ['${CURRENT_LINK}' -> '${REPO}-${VERSION}']"
ln -s ${REPO}-${VERSION} ${CURRENT_LINK}
echo "[INFO] Done"
