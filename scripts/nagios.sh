#!/bin/bash

HOME_DIR=/home/aide/aide
CLIENTS_LOG=${HOME_DIR}/clients/${1}/logs

usage () {
	echo "Usage: $0 client_name."
}

if [ "$1" = "" ]; then
	echo "PLUGIN ERROR no argument provided."
	usage
	exit 3
elif [ ! -d ${HOME_DIR}/clients/${1} ]; then
	echo "AIDE ERROR client does not exist."
	exit 3
elif [ ! "$(ls -A ${CLIENTS_LOG})" > /dev/null ]; then
	echo "AIDE ERROR client does not have logs."
	exit 3
fi

LAST_LOG_FILE=`ls ${CLIENTS_LOG} | grep -P "^${1}-[0-9]{10}" | sort -r| sed -n '1p'`

DATE=`ls ${CLIENTS_LOG}/${LAST_LOG_FILE} | sed -r 's/^[^-]+-([0-9]{10})$/\1/'| xargs -i{} date -d @{} "+%H:%M %F"`

if [ $(expr $(date +%s) - $(ls ${CLIENTS_LOG}/${LAST_LOG_FILE} | sed -r 's/^[^-]+-([0-9]{10})$/\1/')) -ge 86399 ]; then
	echo "AIDE ERROR outdated logs, last log is older than 24h."
	exit 2
fi
	
if  cat ${CLIENTS_LOG}/${LAST_LOG_FILE} | grep "found differences between" >/dev/null ; then
	ADDED=`cat ${CLIENTS_LOG}/${LAST_LOG_FILE} | sed -n '/Added files:/p' | grep -o '[0-9]\+'`
	REMOVED=`cat ${CLIENTS_LOG}/${LAST_LOG_FILE} | sed -n '/Removed files:/p' | grep -o '[0-9]\+'`
	CHANGED=`cat ${CLIENTS_LOG}/${LAST_LOG_FILE} | sed -n '/Changed files:/p' | grep -o '[0-9]\+'`
	echo "${DATE} Added:${ADDED} Removed:${REMOVED} Changed:${CHANGED}"
	exit 1
else
	echo "${DATE} OK"
	exit 0
fi
