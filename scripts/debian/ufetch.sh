#!/bin/sh
#
# ufetch-debian - tiny system info for debian

## INFO

# user is already defined
host="$(hostname)"
os="Debian $(cat /etc/debian_version)"
kernel="$(uname -sr)"
uptime="$(uptime -p | sed 's/up //')"
packages="$(dpkg -l | grep -c ^i)"
shell="$(basename "${SHELL}")"
temp="$(sensors | grep -m 1 'temp1:' | cut -c16-22)"
modelo="$(cat /sys/devices/virtual/dmi/id/product_name)"

## DEFINE COLORS

# probably don't change these
if [ -x "$(command -v tput)" ]; then
	bold="$(tput bold)"
	black="$(tput setaf 0)"
	red="$(tput setaf 1)"
	green="$(tput setaf 2)"
	yellow="$(tput setaf 3)"
	blue="$(tput setaf 4)"
	magenta="$(tput setaf 5)"
	cyan="$(tput setaf 6)"
	white="$(tput setaf 7)"
	reset="$(tput sgr0)"
fi

# you can change these
lc="${reset}${bold}${red}"          # labels
nc="${reset}${bold}${green}"          # user and hostname
ic="${reset}"                       # info
c0="${reset}${red}"                 # first color

## OUTPUT

cat <<EOF

${c0}     ,---._   ${nc}${USER}${ic}@${nc}${host}${reset}
${c0}   /\`  __  \\  ${lc}os      💾  ${ic}${os}${reset}
${c0}  |   /    |  ${lc}kernel  💽  ${ic}${kernel}${reset}
${c0}  |   ${c1}\`.__.\`  ${lc}uptime  ⌛  ${ic}${uptime}${reset}
${c0}   \          ${lc}pkg     📦  ${ic}${packages}${reset}
${c0}    \`-,_      ${lc}model   🖥️ ${ic}${modelo}${reset}
${c0}              ${lc}cputemp ☀️  ${ic}${temp}${reset}

EOF