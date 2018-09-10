#!/bin/bash
#:       Title: recovery.sh - Recovery files from dump and add information about differences to log.
#:    Synopsis: recovery.sh CLIENT LOG
#:        Date: 2018-09-10
#:     Version: 0.9
#:      Author: Paweł Renc
## Script metadata
scriptname=${0##*/}			# name that script is invoked with
## Script options
client="$1"
logfile="$2"
## File localizations
home_dir="/home/aide/aide"	# path to AIDE files
client_recovery="${home_dir}/clients/${client}/recovery"
## Shell additional options
shopt -s extglob 			# turn on extended globbing	
shopt -s nullglob 			# allow globs to return null string
## Function definitions
source ${home_dir}/scripts/info_functions
## Script body
backup_command="${home_dir}/scripts/backup.sh ${client}"
files_to_change=$(awk 'BEGIN{FS=" ";ORS=" "}($0 ~ "^changed:"){print $2}' ${logfile})
files_to_add=$(awk 'BEGIN{FS=" ";ORS=" "}($0 ~ "^added:"){print $2}' ${logfile})
files_to_remove=$(awk 'BEGIN{FS=" ";ORS=" "}($0 ~ "^removed:"){print $2}' ${logfile})
[ ! -z "${files_to_change}" ] && backup_command+=" -c ${files_to_change}"
[ ! -z "${files_to_add}" ] && backup_command+=" -a ${files_to_add}"
[ ! -z "${files_to_remove}" ] && backup_command+=" -r ${files_to_remove}"
eval ${backup_command}
status="$?"
if (( status == 0 )); then
	ok "New files in recovery directory."
	${home_dir}/scripts/backup.sh ${client} -n -c ${files_to_change}
	status="$?"
	if (( status == 0 )); then
		for f in ${files_to_change}; do
			name=${f#/}
			name=${name////@};
			for file in ${client_recovery}"/"${name}.new.+([0-9]); do
				temp=${file}
			done
			[ ! -f ${temp} ] && warrning "${name} has not been found in new dump." && continue
			old_recovery=(${client_recovery}/${name}.old.+([0-9]))
			new_recovery=(${client_recovery}/${name}.new.+([0-9]))
			old_ver=${old_recovery[-1]}
			new_ver=${new_recovery[-1]}
			f=${f////\\/}
			difference=$(diff ${old_ver} ${new_ver})
			diff_status="$?"
			difference=$(echo "${difference}" | sed '$!s/$/\\/')
			if (( diff_status == 1 )); then 
				sed "/^File: ${f}$/i${difference}" ${logfile} > /tmp/xxx #TODO insert after this line
			elif (( diff_status == 2 )); then
				sed "/^File: ${f}$/s@.*@&\nSome troubles were encountered while looking for differences.\n@" ${logfile} > /tmp/xxx #TODO permission denied
			else
				sed "/^File: ${f}$/s@.*@&\nNo differences were found. It means dump is corrupted.\n@" ${logfile} > /tmp/xxx
			fi
			mv /tmp/xxx ${logfile}
		done
		# for f in ${client_recovery}/${name}.new.+([0-9]); do
			# rm -f ${f}
		# done
	else
		sed "1s@.*@Something went wrong during recovery!!!\n\n&@" ${logfile} > /tmp/xxx && mv /tmp/xxx ${logfile}
	fi
else
	warrning "Something went wrong while extracting old versions from archive."
fi
