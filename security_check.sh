#!/bin/bash

# =============================================
#   security_check.sh — проверка и установка
#   инструментов безопасности
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
  echo -e "${RED}❌ Запусти от root: sudo bash security_check.sh${RESET}"
  exit 1
fi

clear

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║       🔐 SECURITY CHECK                  ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${BLUE}📅 Дата:${RESET} $(date '+%d.%m.%Y %H:%M:%S')"
echo -e "${BLUE}🖥️  Хост:${RESET} $(hostname)"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Обновление списка пакетов
echo -e "\n${BLUE}🔄 Обновление списка пакетов...${RESET}"
apt-get update > /dev/null 2>&1
echo -e "${GREEN}✅ Готово${RESET}"

# Массивы для итоговой таблицы
INSTALLED=()
NOT_INSTALLED=()

# -----------------------------------------------
# Функция проверки и установки
# -----------------------------------------------
check_and_install() {
  local NAME=$1       # название для вывода
  local PKG=$2        # имя пакета apt
  local CMD=$3        # команда для проверки статуса

  echo -e "\n${BOLD}🔍 ${NAME}${RESET}"

  if command -v "$PKG" > /dev/null 2>&1 || dpkg -l "$PKG" 2>/dev/null | grep -q "^ii"; then
    INSTALLED+=("$NAME")
    echo -e "  ${GREEN}✅ Установлен${RESET}"

    # Показать статус если есть команда
    if [ -n "$CMD" ]; then
      STATUS=$(eval "$CMD" 2>/dev/null)
      if echo "$STATUS" | grep -qi "active\|running\|enabled"; then
        echo -e "  ${GREEN}▶  Активен${RESET}"
      elif echo "$STATUS" | grep -qi "inactive\|stopped\|disabled"; then
        echo -e "  ${YELLOW}⏸  Неактивен${RESET}"
      fi
    fi
  else
    NOT_INSTALLED+=("$NAME")
    echo -e "  ${RED}❌ Не установлен${RESET}"
    read -p "  Установить $NAME? (y/n): " CONFIRM
    if [ "$CONFIRM" == "y" ]; then
      echo -e "  ${BLUE}⏳ Устанавливаем...${RESET}"
      DEBIAN_FRONTEND=noninteractive apt-get install -y "$PKG" > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✅ Установлен успешно${RESET}"
        # Перемещаем в установленные
        NOT_INSTALLED=("${NOT_INSTALLED[@]/$NAME}")
        INSTALLED+=("$NAME")
      else
        echo -e "  ${RED}❌ Ошибка установки${RESET}"
      fi
    else
      echo -e "  ${YELLOW}⏭️  Пропущено${RESET}"
    fi
  fi
}

# -----------------------------------------------
# Проверка программ
# -----------------------------------------------

check_and_install "fail2ban" "fail2ban" "systemctl is-active fail2ban"
check_and_install "ufw" "ufw" "ufw status"
check_and_install "lynis" "lynis" ""
check_and_install "aide" "aide" ""
check_and_install "auditd" "auditd" "systemctl is-active auditd"

# -----------------------------------------------
# Итоговая таблица
# -----------------------------------------------
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  📊 ИТОГ${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

echo -e "${BOLD}Установлено:${RESET}"
if [ ${#INSTALLED[@]} -eq 0 ]; then
  echo -e "  ${YELLOW}Ничего не установлено${RESET}"
else
  for item in "${INSTALLED[@]}"; do
    [ -n "$item" ] && echo -e "  ${GREEN}✅ $item${RESET}"
  done
fi

echo ""
echo -e "${BOLD}Не установлено:${RESET}"

# Фильтруем пустые элементы
HAS_MISSING=false
for item in "${NOT_INSTALLED[@]}"; do
  if [ -n "$item" ]; then
    echo -e "  ${RED}❌ $item${RESET}"
    HAS_MISSING=true
  fi
done

if [ "$HAS_MISSING" = false ]; then
  echo -e "  ${GREEN}Всё установлено! 🎉${RESET}"
fi

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
