#!/usr/bin/env bash

reset=""
yellow=""
yellow_bold=""
red=""
orange=""

# Returns 0 if the specified string contains the specified substring, otherwise returns 1.
# This exercise it required because we are using the sh-compatible interpretation instead
# of bash.
contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

if test -t 1; then
	# Quick and dirty test for color support
	if contains "$TERM" "256" || contains "$COLORTERM" "256"  || contains "$COLORTERM" "color" || contains "$COLORTERM" "24bit"; then
		reset="\033[0m"
		green="\033[38;5;46m"
		yellow="\033[38;5;178m"
		red="\033[91m"
		orange="\033[38;5;208m"

		emphasis="\033[38;5;226m"
	elif contains "$TERM" "xterm"; then
		reset="\033[0m"
		green="\033[32m"
		yellow="\033[33m"
		red="\033[31;1m"
		orange="\033[31m"

		emphasis="\033[33;1m"
	fi
fi

info="${green}INFO:${reset}"
notice="${yellow}NOTE:${reset}"
warn="${orange}WARN:${reset}"
error="${red}ERROR:${reset}"

# Return a DKIM selector from DKIM_SELECTOR environment variable.
# See README.md for details.
get_dkim_selector() {
	if [ -z "${DKIM_SELECTOR}" ]; then
		echo "mail"
		return
	fi

	local domain="$1"
	local old="$IFS"
	local no_domain_selector="mail"
	local IFS=","
	for part in ${DKIM_SELECTOR}; do
		if contains "$part" "="; then
			k="$(echo "$part" | cut -f1 -d=)"
			v="$(echo "$part" | cut -f2 -d=)"
			if [ "$k" == "$domain" ]; then
				echo "$v"
				IFS="${old}"
				return
			fi
		else
			no_domain_selector="$part"
		fi
	done
	IFS="${old}"

	echo "${no_domain_selector}"
}