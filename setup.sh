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
