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
	for venv_path venv_name in "${(@kv)CONFIG}"; do
		echo "${venv_path}=${venv_name}" >> "${CONFIG_FILE}"
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

new-autoenv() {
    local _name="$1"
	local _python="${2-python}"
	local _path="${3-$(pwd)}"

	_python=$(which ${_python})
	if [[ -d ${_path} ]]; then
		_path=$(realpath ${_path})
	else
		print -P "%F{yellow}WARNING! Path '${_path}' does not exist or it's not a directory. Using current path instead: '$(pwd)'!%f\n"
		_path=$(pwd)
	fi
	_path=${_path%%/}
	read_config
	${_python} -m venv "$CONFIG_PATH/${_name}"
	CONFIG[${_path}]=${_name}
	write_config
}

add-autoenv() {
    local _name="$1"
	local _path="$3"

	read_config
	if [[ -d "${CONFIG_PATH}/${_name}" ]]; then
	    CONFIG[${_path}]=${_name}
	else
	    print -P "%F{red}Virtualenv '${_name}' does not exist!%f\n"
	fi
	write_config
}

get-autoenv-config() {
    column -t -s"=" -N "Location,Name" $CONFIG_FILE
}

get-all-autoenvs() {
    column -t -s"=" -N "Location,Name" -H "Location" $CONFIG_FILE
}
