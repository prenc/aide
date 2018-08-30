#!/bin/bash
HOME_DIR="/home/aide/aide"
TEST_MODE=0
INIT_MODE=0
FILES_TO_CHANGE=()
FILES_TO_ADD=()
FILES_TO_REMOVE=()
TAR_COMMAND_MODE="old"
usage () {
	echo -e "Usage: backup.sh -h hostname <-i | <[-c file...] [-a file...] [-r file...]> [-t]"
	exit 1
}
ok () {
	echo -e "backup.sh: [\e[32mOK\e[0m] $1"
}
error () {
	echo -e "backup.sh: [\e[31mERROR\e[0m] $1"
	exit ${2}
}
if [[ $# -lt 3 ]] ;then usage ;fi
while [[ $# -gt 0 ]]; do
i=$1
	case $i in
		-h)
			SERVER=$2
			shift 2
		;;
		-t)
			TEST_MODE=1
			shift
		;;
		-i|-I)
			INIT_MODE=1
			shift
		;;
		-a)
			FILES_TO_ADD+=($2)
			LAST_ARRAY="FILES_TO_ADD"
			shift 2
			if [[ $? ]]; then error "option without filename" 7; fi
		;;
		-r)
			FILES_TO_REMOVE+=($2)
			LAST_ARRAY="FILES_TO_REMOVE"
			shift 2
			if [[ $? ]]; then error "option without filename" 7; fi
		;;
		-c)
			FILES_TO_CHANGE+=($2)
			LAST_ARRAY="FILES_TO_CHANGE"
			shift 2
			if [[ $? ]]; then error "option without filename" 7; fi
		;;
		-n)
			TAR_COMMAND_MODE="new"
			shift 1
		;;
		*)	if [ ! -z ${LAST_ARRAY} ]; then
				eval ${LAST_ARRAY}=\( \${${LAST_ARRAY}[@]} $1 \)
				shift
			else
				usage
			fi
		;;
	esac
done
if [ -z ${SERVER} ] || [[ ${INIT_MODE} == 1 ]] && ( [ ${#FILES_TO_CHANGE[@]} -ne 0 ] || [ ${#FILES_TO_ADD[@]} -ne 0 ] || [ ${#FILES_TO_REMOVE[@]} -ne 0 ] ); then
	usage
fi
if [ ! -d ${HOME_DIR}/clients/${SERVER}/backup ]; then
	error "No such client or directory structure is corrupted." 2
else
	ok "Client has been found."
fi
if [[ ${INIT_MODE} == 1 ]]; then
	if [ -f ${HOME_DIR}/conf/${SERVER}.conf ]; then
		ok "Client's config file has been found."
	else
		error "Client's config has not been found." 3
	fi
	TAR_COMMAND="ssh aide_spool@${SERVER} sudo tar cvf -"
	while IFS='' read -r input || [[ -n "${input}" ]]; do
		if echo ${input} | grep -P "^/.*CONTENT_EX"> /dev/null; then
			TAR_COMMAND=${TAR_COMMAND}" "$(echo ${input} | sed -r 's|^([^~\*$\\ ]+).*|\1|')
		elif echo ${input} | grep -P "^\!"> /dev/null; then
			TAR_COMMAND=${TAR_COMMAND}" --exclude='"$(echo ${input} | sed -r 's|^\!||' | sed -r 's|^([^~\*$\.\\ ]+).*|\1|')"'"
		fi
	done < ${HOME_DIR}/conf/${SERVER}.conf
	TAR_COMMAND=${TAR_COMMAND}" > ${HOME_DIR}/clients/${SERVER}/backup/dump-$(date +%s).tar"
	if [[ ${TEST_MODE} == 1 ]]; then
		echo ${TAR_COMMAND}
	else
		if eval ${TAR_COMMAND}; then
			ok "New dump has been initialized."
		elif [[ $? == 2 ]]; then
			ok "New dump has been initialized but config file is not perfectly configured."
		else
			error "Something went wrong during dump initialization." 4
		fi
	fi
else
	if [[ ${TEST_MODE} == 1 ]];then
		echo "FILES TO CHANGE: ${FILES_TO_CHANGE[@]}"
		echo "FILES TO ADD: ${FILES_TO_ADD[@]}"
		echo "FILES TO REMOVE: ${FILES_TO_REMOVE[@]}"
		exit 0
	fi
	if $(ls ${HOME_DIR}/clients/${SERVER}/backup | grep -P "^dump-[0-9]{10}.tar$" > /dev/null); then
		BACKUP_FILE=$(ls ${HOME_DIR}/clients/${SERVER}/backup | grep -P "^dump-[0-9]{10}.tar$" | sort -r | sed -ne '1p')
		BACKUP_DATE=$(echo ${BACKUP_FILE} | grep -Po "[0-9]{10}")
		ok "Dump from $(date -d@${BACKUP_DATE} +%D-%T) has been found."
	else
		error "Client does not have dump initialized." 5
	fi
	BACKUP_FILE_PATH="${HOME_DIR}/clients/${SERVER}/backup/${BACKUP_FILE}"
	if [ ${#FILES_TO_CHANGE[@]} -ne 0 ]; then
		TAR_COMMAND="tar xf ${BACKUP_FILE_PATH} --xform='s#^.+/##x' --xform='s#.*#&.${TAR_COMMAND_MODE}.${BACKUP_DATE}#x' -C ${HOME_DIR}/clients/${SERVER}/recovery/"
		for file in ${FILES_TO_CHANGE[@]}; do
			TAR_COMMAND+=" "$(echo ${file} | sed 's#^/##')
		done
		if eval ${TAR_COMMAND};then
			ok "New files in recovery directory."
		elif [[ $? == 2 ]]; then
			ok "Cannot find all files in dump. It is corrupted or you are seeking for temporary files (then conf should be improved)."
		else
			error "Something went wrong with extracting files from archive." 6
		fi
	fi
	if [ "${TAR_COMMAND_MODE}" = "old" ];then 
		for file in ${FILES_TO_ADD[@]}; do 
			# nothing to do yet
			break
		done
		for file in ${FILES_TO_REMOVE[@]}; do 
			# nothing to do yet
			break
		done
		rm "${BACKUP_FILE_PATH}"
		ok "Creating new dump. Please wait..."
		${HOME_DIR}/scripts/backup.sh -h ${SERVER} -i 2>/dev/null
	fi
fi
exit 0