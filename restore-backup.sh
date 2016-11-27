CFG=$1
SRC=$2
DEST=$3

# E.G.: restore-backup.sh archive:archived-email ./restore

rclone copy --config ${CFG} \
      --exclude-from etc/exclude.cnf \
      ${SRC} ${DEST}
