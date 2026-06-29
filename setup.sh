#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SORCE[0]}")" && pwd)"
LOG_FILE="/var/log/setup.log"

#Colors
RED='\033[0;31m';
GREEN='\033[0;32m';
YELLOW='\033[1;33m';
NC='\033[0m'

log() 
ok()
warn()
die()

check_root() {
	[[ "$EUID" -eq 0 ]] || die "Запустите от имени root: sudo bash setup.sh"
}

check_ubuntu() {
	grep -qi ubuntu /etc/os-release || warn "Внимание! ОС не Ubuntu - некоторые шаги могут не сработать!"
	log "OS: "$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\")"
}

