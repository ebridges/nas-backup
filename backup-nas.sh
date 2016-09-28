#!/bin/bash

declare -a PATHS
ROOT='/c'
IFS=$'\n'
PATHS=($(find ${ROOT} \
	      -mindepth 2 \
        -maxdepth 2 \
        -type d | \
            grep -v 'lost+found' | \
            grep -v 'Network Trash Folder' | \
            grep -v 'Virtual Machines.localized' | \
            grep -v 'Temporary Items' | \
            grep -v .TemporaryItems | \
            grep -v .Apple | \
            grep -v .iscsi | \
            grep -v .timemachine | \
            grep -v /c/backup | \
            grep -v /c/home | \
sort)) 2>/dev/null

for p in "${PATHS[@]}"
do
	SYNC_PATH=${p#$(dirname "$(dirname "$p")")/}
	BUCKET='archive'
	if [[ ${SYNC_PATH} == multimedia* ]] || [[ ${SYNC_PATH} == photos* ]] ;
	then	
		BUCKET='multimedia'
	fi
	echo "Synchronizing ${ROOT}/${SYNC_PATH} to ${BUCKET}"
 	$(sync-folder ${ROOT}/${SYNC_PATH} ${BUCKET}:${SYNC_PATH})
done
