#!/usr/bin/env bash

set -euo pipefail

DATE=$(date "+%H:%M:%S %d.%m.%Y")
HOSTNAME=$(hostname)
LOG_FILE=/var/log/monitor.log

#thresholds

THRESHOLD_DISK=80
THRESHOLD_MEM=15
THRESHOLD_LOAD=5
SERVICES=("ssh" "ufw" "fail2ban" "cron")

#func

check_disk() {
	local USAGE=$(df / --output=pcent | tail -n1 | tr -cd '0-9')
	if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
		echo "Не является числом"
		return 2
	fi
	if [ "$USAGE" -ge "$THRESHOLD_DISK" ]; then
		echo "Диск заполнен на $USAGE%!"
		return 1
	fi
	return 0
 }

check_mem() { :; }

check_load() { :; }

check_service() { :; }

main() {
	check_disk
	check_mem
	check_load
	check_service
}

main
