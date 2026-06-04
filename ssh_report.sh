#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

clear

echo "SSH отчёт"

echo "Успешные входы"
journalctl | grep -i sshd | grep -i "accepted" | tail -10

echo ""
echo "Неуспешные входы"
journalctl | grep -i sshd | grep -i "failed password" | tail -10

