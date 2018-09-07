#!/bin/bash
home_dir="/home/aide/aide"	# path to AIDE files
test_mode=0					# invoke script in test mode
init_mode=0					# only initialize dump
tar_commnad_mode="old" 		# extract with label defined in variable
scriptname=${0##*/}			# name that script was invoked with
shopt -s extglob
######### functions
usage () {
	printf "Usage: %s -h hostname <-i | <[-c file...] [-a file...] [-r file...]> [-t] [-n]\n" "$scriptname" >&2
	exit 1
}
ok () {
	printf "%s: [\e[32mOK\e[0m] %s\n" "$scriptname" "$1" >&2
}
error () {
	printf "%s: [\e[31mERROR\e[0m] %s\n" "$scriptname" "$1" >&2
	exit $2
}
######### parse arguments
if [[ $# -lt 3 ]]; then usage; fi
while (( $# )); do
	case $1 in
		-h)
			server=$2
			shift 2
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
			tar_commnad_mode="new"
			shift 1
		;;
		*)	if [ ! -z ${last_array} ]; then
				eval ${last_array}=\( \${${last_array}[@]} $1 \)
				shift
			else
				usage
			fi
		;;
	esac
done
####### check sanity
[ -z ${server} ] && usage
if (( ${init_mode} )) && ([ ${#file_to_change[@]} -ne 0 ] || [ ${#files_to_add[@]} -ne 0 ] || [ ${#files_to_remove[@]} -ne 0 ]); then
	usage
fi
if !(( init_mode )) && [ ${#file_to_change[@]} -eq 0 ] && [ ${#files_to_add[@]} -eq 0 ] && [ ${#files_to_remove[@]} -eq 0 ]; then
	usage
fi
####### check whether client exists
if [ -d ${home_dir}/clients/${server}/backup ]; then
	ok "Client has been found."
else
	error "No such client or directory structure is corrupted." 2
fi
####### script
if (( init_mode )); then
	if [ -f ${home_dir}/conf/${server}.conf ]; then
		ok "Client's config file has been found."
	else
		error "Client's config has not been found." 3
	fi
	tar_command="ssh aide_spool@${server} sudo tar cvf -"
	while IFS='' read -r input || [[ -n "${input}" ]]; do
		if echo ${input} | grep "^/.*CONTENT" > /dev/null; then
			input=${input% [A-Z_]*}
			input=${input%$}
			input=" "${input}
		elif echo ${input} | grep "^\!" > /dev/null; then
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
			ok "New dump has been initialized but config file is not perfectly configured."
		else
			error "Something went wrong during dump initialization." 4
		fi
	fi
else
	if (( test_mode )); then
		echo "FILES TO CHANGE: ${file_to_change[*]}"
		echo "FILES TO ADD: ${files_to_add[*]}"
		echo "FILES TO REMOVE: ${files_to_remove[*]}"
		exit 0
	fi
	if [ -f ${home_dir}/clients/${server}/backup/dump-+([0-9]).tar ]; then
		read backup_file < <(find ./ -type f -name "dump-*.tar" | sort -r)
		backup_date=${backup_file##*-}
		backup_date=${backup_date%%.}
		ok "Dump from "$(date -d@${backup_date} +%D-%T)" has been found."
	else
		error "Client does not have dump initialized." 5
	fi
	backup_path="${home_dir}/clients/${server}/backup/${backup_file}"
	if [ ${#file_to_change[@]} -ne 0 ]; then
		tar_command="tar xf ${backup_path} --xform='s#.*/##x' --xform='s#.*#&.${tar_commnad_mode}.${backup_date}#x' -C ${home_dir}/clients/${server}/recovery/"
		for file in ${file_to_change[@]}; do
			tar_command+=" "${file#/}
		done
		if eval ${tar_command}; then
			ok "New files in recovery directory."
		elif [[ $? == 2 ]]; then
			ok "Cannot find all files in dump. It is corrupted or you are seeking for temporary files (then conf should be improved)."
		else
			error "Something went wrong with extracting files from archive." 6
		fi
	fi
	if [ "${tar_commnad_mode}" = "old" ]; then 
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
		${home_dir}/scripts/${scriptname} -h ${server} -i 2>/dev/null
	fi
fi
exit 0