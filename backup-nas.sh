#!/bin/bash

if [ -e ${HOME}/.profile_cron ];
then
  source ${HOME}/.profile_cron
fi

VERBOSE=
if [[ ${1} == '-v' ]];
then
  VERBOSE='y'
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
sort))

for p in "${PATHS[@]}"
do
  SYNC_PATH=${p#$(dirname "$(dirname "$p")")/}
  BUCKET='archive'
  if [[ ${SYNC_PATH} == multimedia* ]] || [[ ${SYNC_PATH} == photos* ]] ;
  then
    BUCKET='multimedia'
  fi
  if [[ ${VERBOSE} ]];
  then
    echo "Synchronizing ${ROOT}/${SYNC_PATH} to ${BUCKET}"
  fi
  $(sync-folder "${ROOT}/${SYNC_PATH}" "${BUCKET}:${SYNC_PATH}")
done
