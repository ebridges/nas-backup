#!/bin/bash

if [ -e ${HOME}/.profile_cron ];
then
  source ${HOME}/.profile_cron
fi

CONFIG=${1}

if [ -z "${CONFIG}" ];
  echo "Usage: $0 [path/to/config]"
  exit 1
fi

if [ ! -e "${CONFIG}" ];
  echo "${CONFIG} not found!"
  exit 1
fi

declare -a PATHS
ROOT='/c'
IFS=$'\n'
PATHS=($(find ${ROOT} \
        -mindepth 2 \
        -maxdepth 2 \
        -type d  2>/dev/null | \
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
            grep -v /c/usr-local | \
sort))

for LOCAL_PATH in "${PATHS[@]}"
do

  ## LOCAL_PATH --> '/c/documents/bin'
  ## TMP --> 'documents/bin'
  ## REMOTE_PATH --> 'documents:bin'

  TMP=${LOCAL_PATH#$(dirname "$(dirname "$LOCAL_PATH")")/}

  REMOTE_PATH=${TMP/\//:}

  $(sync-folder "${CONFIG}" "${LOCAL_PATH}" "${REMOTE_PATH}")
done
