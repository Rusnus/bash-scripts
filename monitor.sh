#!/usr/bin/env bash

set -euo pipefail

DATE=$(date "+%H:%M:%S %d.%m.%Y")
HOSTNAME=$(hostname)
LOG_FILE=/var/log/monitor.log

#thresholds

THRESHOLD_DISK=80
THRESHOLD_MEM=15
THRESHOLD_LOAD=1.0
SERVICES=("ssh" "ufw" "fail2ban" "cron")

#func

check_disk() {
	local USAGE=$(df / --output=pcent | tail -n1 | tr -cd '0-9')
	if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
		echo "Не является числом"
		return 2
	fi
	if [ "$USAGE" -ge "$THRESHOLD_DISK" ]; then
		echo "Диск заполнен на ${USAGE}%"
		return 1
	fi
	return 0
 }

check_mem() {
	local AVAIL=$(free -m | awk 'NR==2 {print $7}')
	if ! [[ "$AVAIL" =~ ^[0-9]+$ ]]; then
		echo "Не является числом $AVAIL"
		return 2
	fi
	if [ "$AVAIL" -lt "$THRESHOLD_MEM" ]; then
		echo "Заканчивается память, осталось - ${AVAIL} MB"
		return 1
	fi
	return 0
}

check_load() {
	local CORES=$(nproc)
	local LOAD5=$(awk '{print $2}' /proc/loadavg)
	if ! [[ "$LOAD5" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
		echo "Не является числом $LOAD5"
		return 2
	fi
	local OVER=$( echo "$LOAD5 > $CORES * $THRESHOLD_LOAD" | bc )
	if [ "$OVER" -eq 1 ]; then
		echo "Высокая нагрузка на процессор за 5 мин: $LOAD5"
		return 1
	fi
	return 0
 }

check_service() {
	local FAILED=0
	for SERVICE in "${SERVICES[@]}"; do
		if ! systemctl is-active --quiet "$SERVICE"; then
			echo "ВНИМАНИЕ: сервис ${SERVICE} не активен"
			FAILED=1
		fi
	done
	return "$FAILED"
 }

main() {
	local status=0

	check_disk || status=1
	check_mem || status=1
	check_load || status=1
	check_service || status=1

	return "$status"
}

main
