ok "New files in recovery directory."
${home_dir}/scripts/backup.sh -h ${client} -n -c ${FILES_TO_CHANGE}
if [[ ${status} == 0 ]]; then
	for file in ${FILES_TO_CHANGE}; do
		name=$(basename ${file})
		if ! ls ${client_recovery} | grep -P "${name}\.old\.[0-9]{10}" >/dev/null 2>&1; then 
			warrning "No such file in dump."
			continue
		fi
		OLD_VER=${client_recovery}"/"$(ls ${client_recovery} | grep "${name}\.old\." | sort -r | sed -ne '1p')
		NEW_VER=${client_recovery}"/"$(ls ${client_recovery} | grep "${name}\.new\." | sort -r | sed -ne '1p')
		DIFFERENCE=$(diff ${OLD_VER} ${NEW_VER} 2>/dev/null)
		file=$(echo $file | sed 's@\/@\\/@g')
		if [[ ${diff_status} == 1 ]]; then 
			sed "/^File: ${file}$/s@.*@&\n${DIFFERENCE}\n@" ${std_log} > /tmp/xxx
		elif [[ ${diff_status} == 2 ]]; then
			sed "/^File: ${file}$/s@.*@&\nSome troubles were encountered while looking for differences.\n@" ${std_log} > /tmp/xxx
		else
			sed "/^File: ${file}$/s@.*@&\nNo differences were found. It means dump is corrupted.\n@" ${std_log} > /tmp/xxx
		fi
		cat /tmp/xxx > ${std_log}
		rm -f /tmp/xxx
	done
	for file in $(ls ${client_recovery} | grep -P "\.new\.[0-9]{10}"); do
		rm -f ${client_recovery}"/"${file}
	done
else
	sed "1s@.*@No dump initialized! backup.sh -i needed.\n\n&@" ${std_log} > /tmp/xxx
			cat /tmp/xxx > ${std_log}
fi