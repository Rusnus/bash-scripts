#!/bin/bash

# =============================================
#   monitor.sh — мониторинг сервера Ubuntu
# =============================================

# Пороги алертов (в процентах)
CPU_THRESHOLD=80
RAM_THRESHOLD=80
DISK_THRESHOLD=80

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Функция — цвет в зависимости от значения
color_value() {
  local value=$1
  local threshold=$2
  if [ "$value" -ge "$threshold" ]; then
    echo -e "${RED}${value}%${RESET}"
  elif [ "$value" -ge $(( threshold - 20 )) ]; then
    echo -e "${YELLOW}${value}%${RESET}"
  else
    echo -e "${GREEN}${value}%${RESET}"
  fi
}

# Функция — прогресс-бар
progress_bar() {
  local value=$1
  local threshold=$2
  local bar=""
  local filled=$(( value / 5 ))
  local empty=$(( 20 - filled ))

  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done

  if [ "$value" -ge "$threshold" ]; then
    echo -e "${RED}[${bar}]${RESET}"
  elif [ "$value" -ge $(( threshold - 20 )) ]; then
    echo -e "${YELLOW}[${bar}]${RESET}"
  else
    echo -e "${GREEN}[${bar}]${RESET}"
  fi
}

clear

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║         🖥️  SERVER MONITOR               ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# Дата и хост
echo -e "${BLUE}📅 Дата:${RESET}    $(date '+%d.%m.%Y %H:%M:%S')"
echo -e "${BLUE}🖥️  Хост:${RESET}    $(hostname)"
echo -e "${BLUE}⏱️  Uptime:${RESET}  $(uptime -p)"
echo ""

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  РЕСУРСЫ${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# CPU
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'.' -f1)
echo -e "\n${BOLD}CPU:${RESET}"
echo -e "  $(progress_bar $CPU $CPU_THRESHOLD) $(color_value $CPU $CPU_THRESHOLD)"
if [ "$CPU" -ge "$CPU_THRESHOLD" ]; then
  echo -e "  ${RED}⚠️  АЛЕРТ: CPU превышает ${CPU_THRESHOLD}%!${RESET}"
fi

# RAM
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_PERCENT=$(( RAM_USED * 100 / RAM_TOTAL ))
RAM_TOTAL_H=$(free -h | awk '/Mem:/ {print $2}')
RAM_USED_H=$(free -h | awk '/Mem:/ {print $3}')
echo -e "\n${BOLD}RAM:${RESET}"
echo -e "  $(progress_bar $RAM_PERCENT $RAM_THRESHOLD) $(color_value $RAM_PERCENT $RAM_THRESHOLD)  (${RAM_USED_H} / ${RAM_TOTAL_H})"
if [ "$RAM_PERCENT" -ge "$RAM_THRESHOLD" ]; then
  echo -e "  ${RED}⚠️  АЛЕРТ: RAM превышает ${RAM_THRESHOLD}%!${RESET}"
fi

# SWAP
SWAP_TOTAL=$(free -m | awk '/Swap:/ {print $2}')
if [ "$SWAP_TOTAL" -gt 0 ]; then
  SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
  SWAP_PERCENT=$(( SWAP_USED * 100 / SWAP_TOTAL ))
  SWAP_USED_H=$(free -h | awk '/Swap:/ {print $3}')
  SWAP_TOTAL_H=$(free -h | awk '/Swap:/ {print $2}')
  echo -e "\n${BOLD}SWAP:${RESET}"
  echo -e "  $(progress_bar $SWAP_PERCENT $RAM_THRESHOLD) $(color_value $SWAP_PERCENT $RAM_THRESHOLD)  (${SWAP_USED_H} / ${SWAP_TOTAL_H})"
fi

# ДИСК
echo -e "\n${BOLD}ДИСК:${RESET}"
df -h | grep -v tmpfs | grep -v udev | grep "^/" | while read line; do
  MOUNT=$(echo $line | awk '{print $6}')
  USED_PERCENT=$(echo $line | awk '{print $5}' | tr -d '%')
  USED=$(echo $line | awk '{print $3}')
  TOTAL=$(echo $line | awk '{print $2}')
  echo -e "  ${CYAN}${MOUNT}${RESET}  $(progress_bar $USED_PERCENT $DISK_THRESHOLD) $(color_value $USED_PERCENT $DISK_THRESHOLD)  (${USED} / ${TOTAL})"
  if [ "$USED_PERCENT" -ge "$DISK_THRESHOLD" ]; then
    echo -e "  ${RED}⚠️  АЛЕРТ: Диск ${MOUNT} превышает ${DISK_THRESHOLD}%!${RESET}"
  fi
done

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  ТОП 5 ПРОЦЕССОВ ПО CPU${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
printf "  ${BOLD}%-8s %-8s %-8s %s${RESET}\n" "PID" "CPU%" "RAM%" "ПРОЦЕСС"
echo "  ----------------------------------------"
ps aux --sort=-%cpu | awk 'NR>1 && NR<=6 {printf "  %-8s %-8s %-8s %s\n", $2, $3, $4, $11}'

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  ТОП 5 ПРОЦЕССОВ ПО RAM${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
printf "  ${BOLD}%-8s %-8s %-8s %s${RESET}\n" "PID" "CPU%" "RAM%" "ПРОЦЕСС"
echo "  ----------------------------------------"
ps aux --sort=-%mem | awk 'NR>1 && NR<=6 {printf "  %-8s %-8s %-8s %s\n", $2, $3, $4, $11}'

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${CYAN}  Пороги алертов: CPU>${CPU_THRESHOLD}%  RAM>${RAM_THRESHOLD}%  DISK>${DISK_THRESHOLD}%${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
