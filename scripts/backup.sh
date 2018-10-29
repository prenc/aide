#!/bin/bash
#:       Title: backup.sh - Manages dump of neuralgic client's system files.
#:    Synopsis: backup.sh HOSTNAME [-t] [-n] [-h] HOSTNAME -i | [-f file...]
#:        Date: 2018-09-07
#:     Version: 0.9
#:      Author: Paweł Renc
#:     Options: -i - Initialize dump based on config file
#:              -h - Print usage information
#:              -t - Invoke script in test mode; print commands instead of
## Script metadata
scriptname=${0##*/}			# name that script is invoked with
usage_information="${scriptname} [-t] [-n] [-h] HOSTNAME -i | [-f file...]"
description="Manages dump of neuralgic client's system files."
## Script options
test_mode=0					# run script in test mode (default 0 - false)
init_mode=0					# only initialize dump (default 0 - false)
tar_command_mode=0 		# type of exstraction (default 0 - "old", 1 - "new")
## File localizations
home_dir="/home/aide/aide"	# path to AIDE files
## Shell additional options
shopt -s extglob 			# turn on extended globbing
shopt -s nullglob			# enable null globbs
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
		-f)
			changed_files+=($2)
			shift 2
			if (( $? )); then error "Pass filenames after -f option." 7; fi
		;;
		-n)
			tar_command_mode=1
			shift
		;;
		*)
			if (( ${#changed_files[@]} != 0 )); then
				changed_files+=($1)
				shift
			else
				[[ -z ${server} ]] && server=$1 || usage
				shift
			fi
		;;
	esac
done
# Check sanity of arguments
[[ -z ${server} ]] && usage
if (( init_mode == 0 )) && (( ${#changed_files[@]} == 0 )) ; then
	usage
fi
# Check whether client exists
if [[ -d ${home_dir}/clients/${server}/backup ]]; then
	ok "Client has been found."
else
	error "No such client or directory structure is corrupted." 2
fi
## Check whether client has backup and recovery feature enabled
while IFS='' read -r input || [[ -n "${input}" ]]; do
	if [[ ${input} =~ ^${server} ]]; then
		server_ip=${input#${server} }
	fi
done < "${home_dir}/recovery_clients.conf"
[[ -z ${server_ip} ]] && error "${server} has backup and recovery feature disabled." 8 || ok "${server}'s ip is ${server_ip}"
## Initialize dump or extract files from existing one
if (( init_mode )); then
	## Initialize dump
	if [[ -f ${home_dir}/conf/${server}.conf ]]; then
		ok "Client's config file has been found."
	else
		error "Client's config has not been found." 3
	fi
	## Construct tar command
	tar_command="ssh aide_spool@${server_ip} sudo tar cvf -"
	if (( ${#changed_files[@]} )); then
		### Create dump only from files which are passed as arguments
		for f in "${changed_files[@]}"; do
			tar_command+=" "${f}
		done
	else
		### Create full dump based on config file
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
	fi
	tar_command+=" > ${home_dir}/clients/${server}/backup/dump-$(date +%s).tar"
	## Download files from clients
	if (( test_mode )); then
		printf "%s\n" "${tar_command}"
	else
		## Two modes depending whether it is dump initialization or only dump complementation
		if (( ! ${#changed_files[@]} )); then
			### Remove old dump's files
			for f in ${home_dir}/clients/${server}/backup/*; do
				rm -f ${f}
			done
			### Create new full dump
			if eval ${tar_command} 2>/dev/null; then
				ok "New dump has been initialized."
			elif [[ $? == 2 ]]; then
				warrning "New dump has been initialized but config file is not perfectly configured."
			else
				error "Something went wrong during dump initialization." 4
			fi
		else
			### Create main dump complementation
			if eval ${tar_command} "--no-recursion" 2>/dev/null; then
				ok "Changed files has been downloaded properly."
			elif [[ $? == 2 ]]; then
				warrning "No all changed files has been downloaded."
			else
				error "Something went wrong while downloading files." 4
			fi
		fi
	fi
else
	## Print which files would be exstracted
	if (( test_mode )); then
		printf "FILES TO CHANGE: %s\n" "${changed_files[*]}"
		exit 0
	fi
	backup_files=(${home_dir}/clients/${server}/backup/dump-+([0-9]).tar)
	(( ${#backup_files[@]} )) || error "Client does not have any dump initialized." 5
	## Extract files from existing dump
	for changed_file in ${changed_files[@]}; do
		### Iterate through dump starting from newest in order to find the newest version of file
		for (( i=1;i<=${#backup_files[@]};i++ )); do
			backup_file=${backup_files[-${i}]}
			backup_date=${backup_file##*-}
			backup_date=${backup_date%%.tar}
			if (( ${tar_command_mode} )); then
				version_mark="new"
			else
				version_mark="old"
			fi
			shopt -u nullglob
			tar_command="tar xf ${backup_file} --xform='s#/#@#g' --xform='s#.*#&.${version_mark}.${backup_date}#' --no-recursion -C ${home_dir}/clients/${server}/recovery/ ${changed_file#/} "
			if eval ${tar_command}; then
				ok "File ${changed_file} from "$(date -d@${backup_date} +%D-%T)" has been found."
				break
			fi
		done
	done
	if (( ! ${tar_command_mode} )); then
		### Download only changed files from client
		${home_dir}/scripts/backup.sh ${server} -i -f ${changed_files[@]}
	fi
	## Change permissons
	chmod 600 ${home_dir}/clients/${server}/recovery/*
fi
exit 0
