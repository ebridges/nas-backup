#!/bin/bash

if [ -e ${HOME}/.profile_cron ] ;
then
  source ${HOME}/.profile_cron
fi

CONFIG=${1}
FILE_LIST=${2}

if [ -z "${CONFIG}" ] || [ -z "${FILE_LIST}" ] ;
then
  echo "Usage: $0 [path/to/config] [path/to/file-list]"
  exit 1
fi

if [ ! -e "${CONFIG}" ];
then
  echo "${CONFIG} not found!"
  exit 1
fi

if [ ! -e "${FILE_LIST}" ];
then
  echo "${FILE_LIST} not found!"
  exit 1
fi

while IFS=, read LOCAL_PATH REMOTE_PATH
do
  $(sync-folder "${CONFIG}" "${LOCAL_PATH}" "${REMOTE_PATH}")
done < ${FILE_LIST}
