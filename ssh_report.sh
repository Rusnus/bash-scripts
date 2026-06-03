#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

clear

clear

echo -e "${BOLD}${CYAN}"
echo "========================================"
echo "  SSH ОТЧЁТ"
echo "========================================"
echo -e "${RESET}"

echo -e "${BOLD}____________________________________${RESET}"
echo -e "\n${BOLD}${GREEN}  УСПЕШНЫЕ ВХОДЫ${RESET}"
echo -e "${BOLD}____________________________________${RESET}"
echo ""
journalctl | grep -i sshd | grep -i accepted | tail -15
