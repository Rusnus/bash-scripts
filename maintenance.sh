#!/bin/bash

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Запусти от root: sudo bash maintenance.sh${RESET}"
  exit 1
fi

clear

echo -e "Дата: $(date '+%d.%m.%Y %H:%M:%S')"
echo -e "Хост: $(hostname)"
echo ""

# Место до очистки
BEFORE=$(df -k / | awk 'NR==2 {print $4}')
echo -e "Свободно места до очистки: ${BEFORE}${RESET}"
echo ""

printf '%0.s─' {1..30}

# 1. Очистка старых логов
echo -e "\n Очистка логов старше 7 дней..."
find /var/log -type f -name "*.log" -mtime +7 -delete 2>/dev/null
find /var/log -type f -name "*.gz" -mtime +7 -delete 2>/dev/null
echo -e "${GREEN} Готово${RESET}"

# 2. Очистка /tmp
echo -e "\n Очистка /tmp..."
find /tmp -type f -mtime +1 -delete 2>/dev/null
find /tmp -type d -empty -mtime +1 -delete 2>/dev/null
echo -e "${GREEN} Готово${RESET}"

# 3. Очистка кэша apt
echo -e "\n Очистка кэша apt..."
apt-get clean -y > /dev/null 2>&1
apt-get autoclean -y > /dev/null 2>&1
apt-get autoremove -y > /dev/null 2>&1
echo -e "${GREEN} Готово${RESET}"

# 4. Очистка journald логов старше 7 дней
echo -e "\n Очистка системных журналов (journald)..."
journalctl --vacuum-time=7d 2>/dev/null
echo -e "${GREEN} Готово${RESET}"

# Место после очистки

printf '%0.s─' {1..30}
echo ""
AFTER=$(df -k / | awk 'NR==2 {print $4}')
DIFF=$(( AFTER - BEFORE ))

if [ "$DIFF" -ge 1024 ]; then
    DIFF_MB=$(( DIFF / 1024 ))
    echo "Освобождено: ${DIFF} KB / ${DIFF_MB} MB"
else
    echo " Освобождено: ${DIFF} KB"
fi

echo ""
echo -e "${GREEN} Обслуживание завершено!${RESET}"
printf '%0.s─' {1..30}
echo ""
