#!/bin/bash
HOME_DIR="/home/aide/aide"
TEST_MODE=0
INIT_MODE=0
FILES_CHANGE=()
FILES_ADD=()
FILES_REMOVE=()
usage () {
	echo -e "Usage: backup.sh -h hostname <-i | <[-c file...] [-a file...] [-r file...]> [-t]"
	exit 1
}
ok () {
	echo -e "[\e[32mOK\e[0m] $1"
}
error () {
	echo -e "[\e[31mERROR\e[0m] $1"
	exit ${2}
}
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
			FILES_ADD+=($2)
			LAST_ARRAY="FILES_ADD"
			shift 2
		;;
		-r)
			FILES_REMOVE+=($2)
			LAST_ARRAY="FILES_REMOVE"
			shift 2
		;;
		-c)
			FILES_CHANGE+=($2)
			LAST_ARRAY="FILES_CHANGE"
			shift 2
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
if [[ ${TEST_MODE} ]];then
	echo "FILES_CHANGE: ${FILES_CHANGE[@]}"
	echo "FILES_ADD: ${FILES_ADD[@]}"
	echo "FILES_REMOVE: ${FILES_REMOVE[@]}"
fi
if [ -z ${SERVER} ]; then
	usage
fi
#clear
if [ ! -d ${HOME_DIR}/clients/${SERVER}/backup ]; then
	error "No such client or his structure of file corrupted." 2
else
	ok "Client has been found."
fi
TAR_COMMAND="ssh aide_spool@${SERVER} sudo tar cvzf -"
if [[ ${INIT_MODE} == 1 ]]; then
	if [ -f ${HOME_DIR}/conf/${SERVER}.conf ]; then
		ok "Client's file has been found."
	else
		error "Client's config has not been found." 3
	fi
	while IFS='' read -r input || [[ -n "${input}" ]]; do
		if echo ${input} | grep -P "^/.*CONTENT_EX"> /dev/null; then
			TAR_COMMAND=${TAR_COMMAND}" "$(echo ${input} | sed -r 's|^([^~\*$\\ ]+).*|\1|')
		elif echo ${input} | grep -P "^\!"> /dev/null; then
			TAR_COMMAND=${TAR_COMMAND}" --exclude='"$(echo ${input} | sed -r 's|^\!||' | sed -r 's|^([^~\*$\.\\ ]+).*|\1|')"'"
		fi
	done < ${HOME_DIR}/conf/${SERVER}.conf
	TAR_COMMAND=${TAR_COMMAND}" > ${HOME_DIR}/clients/${SERVER}/backup/backup-$(date +%s).tar.gz"
	if [[ ${TEST_MODE} == 1 ]]; then
		echo ${TAR_COMMAND}
	else
		eval ${TAR_COMMAND}
	fi
else
	echo "this part of script is under constraction"
fi
