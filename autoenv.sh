#!/usr/bin/env zsh

CONFIG_PATH="$HOME/.config/.autoenv"
CONFIG_FILE="${CONFIG_PATH}/autoenv.conf"

declare -A CONFIG

config_setup() {
	[[ ! -d "${CONFIG_PATH}" ]] && mkdir -p "$CONFIG_PATH"
	[[ ! -f "${CONFIG_FILE}" ]] && touch "$CONFIG_FILE"
}

read_config() {
	# local -A config

	while read -r line; do
		IFS="=" read -r key value <<< "$line"
		CONFIG[$key]=$value
	done < "${CONFIG_FILE}"
}

write_config() {
	cat /dev/null > "${CONFIG_FILE}"
	for i in "${!CONFIG[@]}"
    do
        key="$i"
        value="${CONFIG[$i]}"
		echo "${key}=${value}" >> "${CONFIG_FILE}"
    done
}

smart_venv_activate() {
	read_config
	venv_activate=0
	if [[ ${#CONFIG[@]} -gt 0 ]]; then
		for venv_path venv_name in "${(@kv)CONFIG}"; do
			if [[ "$PWD" == $venv_path* ]]; then
				venv_activate=1
				current_env="$VIRTUAL_ENV"
				if [[ "$current_env" != "${venv_path%%/}/${venv_name}" ]]; then
					absolute_path="$(realpath "${CONFIG_PATH%%/}/${venv_name}")"
					path_to_activate="${absolute_path%%/}/bin/activate"
					source "${path_to_activate}"
				fi
			fi
		done
	fi
	[[ $venv_activate = 0 && "${#VIRTUAL_ENV}" -gt 0 ]] && deactivate
}
