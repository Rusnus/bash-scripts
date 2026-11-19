#!/usr/bin/env bash

set -euo pipefail

LOG_FILE=/var/log/monitor.log
log() { echo "$(date "+%Y-%m-%d %H:%M:%S") $HOSTNAME $1 $2" | tee -a "$LOG_FILE"; }

#thresholds

THRESHOLD_DISK=80 # % заполнения диска /
THRESHOLD_MEM=270 # MB (нижний предел)
THRESHOLD_LOAD=1.0 # коэф на ядро
SERVICES=("ssh" "ufw" "fail2ban" "cron")

#func

check_disk() {
	local USAGE=$(df / --output=pcent | tail -n1 | tr -cd '0-9')
	if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
		log ERROR "Не является числом $USAGE (проверка диска)"
		return 2
	fi
	if [ "$USAGE" -ge "$THRESHOLD_DISK" ]; then
		log WARN "Диск заполнен на ${USAGE}%"
		return 1
	fi
	return 0
 }

check_mem() {
	local AVAIL=$(free -m | awk 'NR==2 {print $7}')
	if ! [[ "$AVAIL" =~ ^[0-9]+$ ]]; then
		log ERROR "Не является числом $AVAIL (проверка памяти)"
		return 2
	fi
	if [ "$AVAIL" -lt "$THRESHOLD_MEM" ]; then
		log WARN "Заканчивается память, осталось - ${AVAIL} MB"
		return 1
	fi
	return 0
}

check_load() {
	local CORES=$(nproc)
	local LOAD5=$(awk '{print $2}' /proc/loadavg)
	if ! [[ "$LOAD5" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
		log ERROR "Не является числом $LOAD5 (проверка процессов)"
		return 2
	fi
	local OVER=$( echo "$LOAD5 > $CORES * $THRESHOLD_LOAD" | bc )
	if [ "$OVER" -eq 1 ]; then
		log WARN "Высокая нагрузка на процессор за 5 мин: $LOAD5"
		return 1
	fi
	return 0
 }

check_service() {
	local FAILED=0
	for SERVICE in "${SERVICES[@]}"; do
		if ! systemctl is-active --quiet "$SERVICE"; then
			log WARN "Cервис ${SERVICE} не активен"
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
