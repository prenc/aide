#!/bin/bash
#:       Title: nagios.sh - Informs Nagios about last AIDE log result.
#:    Synopsis: nagios.sh [-h] HOSTNAME 
#:        Date: 2018-09-11
#:     Version: 1.0
#:      Author: Paweł Renc
#:     Options: -h - Print usage information
## Script metadata
scriptname=${0##*/}			# name that script is invoked with
description="Inform Nagios about last AIDE log result."
usage_information="${scriptname} [-h] HOSTNAME"
## File localizations
home_dir="/home/aide/aide"
clients_log="${home_dir}/clients/${1}/logs"
## Shell additional options
shopt -s extglob 			# turn on extended globbing	
shopt -s nullglob 			# allow globs to return null string
## Script options
added=0
removed=0
changed=0
## Function definitions
source "${home_dir}/scripts/info_functions"
## Parse command-line options
while (( $# )); do
	case $1 in
	-h) usage 3;;
	*) break
	esac
done
## Check sanity
[[ -z $1 ]] && usage 3
[[ ! -d ${home_dir}/clients/${1} ]] && echo "AIDE ERROR client does not exist." && exit 3
is_empty=(${clients_log}/*)
(( ${#is_empty[@]} )) || (echo "AIDE ERROR client does not have logs." && exit 3)
## Script body
for log in ${clients_log}/${1}-+([0-9]); do
	last_log=${log}
done
date=$(date -d @${last_log##*-} "+%H:%M %F")
## Check whether the log is too old
if (( ($(date +%s) - ${last_log##*-}) > 86399 )); then
	echo "AIDE ERROR outdated logs, the last log file is older than 24h."
	exit 2
fi	
if grep "found differences between" ${last_log} > /dev/null ; then
	added=$(sed -n '/Added files:/p' ${last_log} | grep -o '[0-9]\+')
	removed=$(sed -n '/Removed files:/p' ${last_log} | grep -o '[0-9]\+')
	changed=$(sed -n '/Changed files:/p' ${last_log} | grep -o '[0-9]\+')
	echo "${date} Added:${added} Removed:${removed} Changed:${changed} | Added=${added};300;500;900;0 Removed=${removed};300;500;900;0 Changed=${changed};300;500;900;0"
	exit 1
else
	echo "${date} OK | Added=${added};300;500;900;0 Removed=${removed};300;500;900;0 Changed=${changed};300;500;900;0"
	exit 0
fi
