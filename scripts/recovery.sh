#!/bin/bash
#:       Title: recovery.sh - Recovers files from dump and add information about differences to log.
#:    Synopsis: recovery.sh CLIENT_NAME LOG_FILE
#:        Date: 2018-09-10
#:     Version: 0.9
#:      Author: Paweł Renc
#:     Options: -h - Print usage information
## Script metadata
scriptname=${0##*/}			# name that script is invoked with
usage_information="${scriptname} [-h] CLIENT_NAME LOG_FILE"
description="Recovers files from dump."
## File localizations
home_dir="/home/aide/aide"	# path to AIDE files
## Shell additional options
shopt -s extglob 			# turn on extended globbing
shopt -s nullglob 			# allow globs to return null string
## Function definitions
source ${home_dir}/scripts/info_functions
## Parse command-line options
while (( $# )); do
	case $1 in
	-h)
		usage
	;;
	*)
		client="$1"
    logfile="$2"
		shift 2
	esac
done
client_recovery="${home_dir}/clients/${client}/recovery"
## Script body
backup_command="${home_dir}/scripts/backup.sh ${client}"
files_to_change=$(awk 'BEGIN{FS=" ";ORS=" "}($0 ~ "^changed:"){print $2}' ${logfile} 2>/dev/null)
[[ ! -z ${files_to_change} ]] && backup_command+=" -f ${files_to_change}"
eval ${backup_command}
status=$?
if (( status == 0 )); then
	ok "${client}: New files in recovery directory."
	info "Extracting files from new dump."
	${home_dir}/scripts/backup.sh ${client} -n -f ${files_to_change}
	if (( $? == 0 )); then
		for f in ${files_to_change}; do
			name="${f#/}"
			name="${name////@}"
			old_recovery=(${client_recovery}/${name}.old.+([0-9]))
			new_recovery=(${client_recovery}/${name}.new.+([0-9]))
			[[ ${#new_recovery[@]} == 0 ]] && { warrning "${name} has not been found in new dump." && continue; }
			old_ver="${old_recovery[-1]}"
			new_ver="${new_recovery[-1]}"
			f="${f////\\/}"
			difference=$(diff ${old_ver} ${new_ver})
			diff_status="$?"
			difference=$(echo "${difference}" | sed '$!s/$/\\/')
			if (( diff_status == 1 )); then
				if (( ${#difference} > 1000 )); then
					sed "/^File: ${f}$/a The difference counts over 1000 characters." "${logfile}" > /tmp/xxx
				else
					sed "/^File: ${f}$/a ${difference}" "${logfile}" > /tmp/xxx
				fi
			elif (( diff_status == 2 )); then
				sed "/^File: ${f}$/a Some troubles were encountered while looking for differences. (It can be binary file.)" "${logfile}" > /tmp/xxx
			else
				sed "/^File: ${f}$/a No differences were found. It means dump is corrupted." "${logfile}" > /tmp/xxx
			fi
			mv -f /tmp/xxx "${logfile}"
			### Remove files extracted only to compare
			for f in "${new_recovery[@]}"; do
				rm -rf "${f}"
			done
		done
	else
		sed "1i Something went wrong during recovery\!\n\n" ${logfile} > /tmp/xxx && mv -f /tmp/xxx ${logfile}
	fi
else
	error "Something went wrong while extracting old versions from archive." 2
fi
## Remove recovered files older than 3 days
for f in ${client_recovery}/${name}.old.+([0-9]); do
	(( $(date -d"3 days ago" +%s) > ${f##*old.} )) && rm -fr "${f}"
done
## Theoretically not needed
# for f in ${client_recovery}/${name}.new.+([0-9]); do
# 	rm -fr "${f}"
# done
