SRC=$1
DEST=$2

# E.G.: restore-backup.sh archive:archived-email ./restore

rclone copy ${SRC} ${DEST} --config etc/rclone-config.cnf --exclude-from etc/exclude.cnf
