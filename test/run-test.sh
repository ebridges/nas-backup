config=$1
files=$2
verbose=$3
while IFS=, read src dest;
do
    echo "[Running Test] Sync from ${src} to ${dest}"
    rclone sync ${src} ${dest} --config ${config} --checksum ${verbose}
    echo "[Test Complete] ${src} -> ${dest}"
done < ${files}

