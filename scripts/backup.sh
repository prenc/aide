#!/bin/bash
#:       Title: backup.sh - Manages dump of neuralgic client's system files.
#:    Synopsis: backup.sh HOSTNAME [-t] [-n] [-h] -i | [-c file...] [-a file...] [-r file...]
#:        Date: 2018-09-07
#:     Version: 0.9
#:      Author: Paweł Renc
#:     Options: -i - Initialize dump based on config file
#:              -h - Print usage information
#:              -t - Invoke script in test mode; print commands instead of 
## Script metadata
scriptname=${0##*/}			# name that script is invoked with
usage_information="${scriptname} [-t] [-n] [-h] HOSTNAME -i | [-c file...] [-a file...] [-r file...]"
description="Manages dump of neuralgic client's system files."
## Script options
test_mode=0					# run script in test mode (default 0 - false)
init_mode=0					# only initialize dump (default 0 - false)
tar_command_mode="old" 		# extract with label defined in variable (default "old")
## File localizations
home_dir="/home/aide/aide"	# path to AIDE files
## Shell additional options
shopt -s extglob 			# turn on extended globbing			
## Function definitions
source ${home_dir}/scripts/info_functions
## Parse command-line options
while (( $# )); do
	case $1 in
		-h)
			usage
		;;
		-t)
			test_mode=1
			shift
		;;
		-i)
			init_mode=1
			shift
		;;
		-a)
			files_to_add+=($2)
			last_array="files_to_add"
			shift 2
			if (( $? )); then error "option without filename" 7; fi
		;;
		-r)
			files_to_remove+=($2)
			last_array="files_to_remove"
			shift 2
			if (( $? )); then error "option without filename" 7; fi
		;;
		-c)
			file_to_change+=($2)
			last_array="file_to_change"
			shift 2
			if (( $? )); then error "option without filename" 7; fi
		;;
		-n)
			tar_command_mode="new"
			shift 1
		;;
		*)	if [[ ! -z ${last_array} ]]; then
				eval ${last_array}=\( \${${last_array}[@]} $1 \)
				shift
			else
				[[ -z ${server} ]] && server=$1 || usage
				shift
			fi
		;;
	esac
done
# Check sanity
[[ -z ${server} ]] && usage
if (( init_mode )) && ([[ ${#file_to_change[@]} -ne 0 ]] || [[ ${#files_to_add[@]} -ne 0 ]] || [[ ${#files_to_remove[@]} -ne 0 ]]); then
	usage
fi
if (( init_mode == 0 )) && (( ${#file_to_change[@]} == 0 )) && (( ${#files_to_add[@]} == 0 )) && (( ${#files_to_remove[@]} == 0 )); then
	usage
fi
# Check whether client exists
if [[ -d ${home_dir}/clients/${server}/backup ]]; then
	ok "Client has been found."
else
	error "No such client or directory structure is corrupted." 2
fi
# Initialize dump or extract from existing one
if (( init_mode )); then
	if [[ -f ${home_dir}/conf/${server}.conf ]]; then
		ok "Client's config file has been found."
	else
		error "Client's config has not been found." 3
	fi
	tar_command="ssh aide_spool@${server} sudo tar cvf -"
	while IFS='' read -r input || [[ -n "${input}" ]]; do
		if [[ ${input} =~ ^/.*CONTENT ]]; then
			input=${input%%?($)+( )[A-Z_]*}
			input=" "${input}
		elif [[ ${input} =~ ^\! ]]; then
			input=${input#\!}
			input=${input%$}
			input=" --exclude='"${input}"'"
		else
			continue
		fi
		tar_command+=${input}
	done < ${home_dir}/conf/${server}.conf
	tar_command+=" > ${home_dir}/clients/${server}/backup/dump-$(date +%s).tar"
	if (( test_mode )); then
		printf "%s\n" "${tar_command}"
	else
		if eval ${tar_command}; then
			ok "New dump has been initialized."
		elif [[ $? == 2 ]]; then
			warrning "New dump has been initialized but config file is not perfectly configured."
		else
			error "Something went wrong during dump initialization." 4
		fi
	fi
else
	if (( test_mode )); then
		printf "FILES TO CHANGE: %s\n" "${file_to_change[*]}"
		printf "FILES TO ADD: %s\n" "${files_to_add[*]}"
		printf "FILES TO REMOVE: %s\n" "${files_to_remove[*]}"
		exit 0
	fi
	for f in ${home_dir}/clients/${server}/backup/dump-+([0-9]).tar; do
		backup_file=$f
	done
	if [[ -z ${backup_file} ]]; then 
		error "Client does not have any dump." 5
	else
		backup_file=${backup_file##*/}
		backup_date=${backup_file##*-}
		backup_date=${backup_date%%.tar}
		ok "Dump from "$(date -d@${backup_date} +%D-%T)" has been found."
	fi
	backup_path="${home_dir}/clients/${server}/backup/${backup_file}"
	if [[ ${#file_to_change[@]} -ne 0 ]]; then
		tar_command="tar xf ${backup_path} --xform='s#/#@#g' --xform='s#.*#&.${tar_command_mode}.${backup_date}#x' -C ${home_dir}/clients/${server}/recovery/"
		for file in ${file_to_change[@]}; do
			tar_command+=" "${file#/}
		done
		if eval ${tar_command}; then
			ok "New files in recovery directory."
		elif [[ $? == 2 ]]; then
			warrning "Cannot find all files in dump. It is corrupted or you are seeking for temporary files (then config should be improved)."
		else
			error "Something went wrong with extracting files from archive." 6
		fi
		chmod 600  ${home_dir}/clients/${server}/recovery/*
	fi
	if [[ "${tar_command_mode}" = "old" ]]; then
		## idea of updating dump instead of initializating each time
		for file in ${files_to_add[@]}; do 
			# nothing to do yet
			break
		done
		for file in ${files_to_remove[@]}; do 
			# nothing to do yet
			break
		done
		rm "${backup_path}"
		ok "Creating new dump. Please wait..."
		${home_dir}/scripts/${scriptname} ${server} -i 2>/dev/null
	fi
fi
exit 0