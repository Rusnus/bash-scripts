#!/bin/bash

# =============================================
#   maintenance.sh — обслуживание сервера
# =============================================

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Запусти от root: sudo bash maintenance.sh${RESET}"
  exit 1
fi

clear

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║       🔧 SERVER MAINTENANCE              ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${BLUE}📅 Дата:${RESET} $(date '+%d.%m.%Y %H:%M:%S')"
echo -e "${BLUE}🖥️  Хост:${RESET} $(hostname)"
echo ""

# Место до очистки
BEFORE=$(df -h / | awk 'NR==2 {print $4}')
echo -e "${BOLD}💾 Свободно места до очистки: ${YELLOW}${BEFORE}${RESET}"
echo ""

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# 1. Очистка старых логов
echo -e "\n${BOLD}📋 Очистка логов старше 7 дней...${RESET}"
find /var/log -type f -name "*.log" -mtime +7 -delete 2>/dev/null
find /var/log -type f -name "*.gz" -mtime +7 -delete 2>/dev/null
echo -e "${GREEN}✅ Готово${RESET}"

# 2. Очистка /tmp
echo -e "\n${BOLD}🗑️  Очистка /tmp...${RESET}"
find /tmp -type f -mtime +1 -delete 2>/dev/null
find /tmp -type d -empty -mtime +1 -delete 2>/dev/null
echo -e "${GREEN}✅ Готово${RESET}"

# 3. Очистка кэша apt
echo -e "\n${BOLD}📦 Очистка кэша apt...${RESET}"
apt-get clean -y > /dev/null 2>&1
apt-get autoclean -y > /dev/null 2>&1
apt-get autoremove -y > /dev/null 2>&1
echo -e "${GREEN}✅ Готово${RESET}"

# 4. Очистка journald логов старше 7 дней
echo -e "\n${BOLD}📰 Очистка системных журналов (journald)...${RESET}"
journalctl --vacuum-time=7d 2>/dev/null
echo -e "${GREEN}✅ Готово${RESET}"

# 5. Обновление пакетов
echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}🔄 Проверка обновлений...${RESET}"
apt-get update -y > /dev/null 2>&1
UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -c upgradable)

if [ "$UPGRADABLE" -gt 1 ]; then
  COUNT=$((UPGRADABLE - 1))
  echo -e "${YELLOW}⬆️  Доступно обновлений: ${COUNT}${RESET}"
  read -p "Установить? (y/n): " CONFIRM
  if [ "$CONFIRM" == "y" ]; then
    echo -e "${BLUE}⏳ Обновляем...${RESET}"
    apt-get upgrade -y > /dev/null 2>&1
    apt-get full-upgrade -y > /dev/null 2>&1
    echo -e "${GREEN}✅ Пакеты обновлены${RESET}"
  else
    echo -e "${YELLOW}⏭️  Обновление пропущено${RESET}"
  fi
else
  echo -e "${GREEN}✅ Нет обновлений${RESET}"
fi

# Место после очистки
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
AFTER=$(df -h / | awk 'NR==2 {print $4}')
echo -e "${BOLD}💾 Свободно места после очистки: ${GREEN}${AFTER}${RESET}"
echo ""
echo -e "${GREEN}${BOLD}✅ Обслуживание завершено!${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
