#!/bin/bash

# =============================================
#   setup_swap.sh — настройка swap в Ubuntu
# =============================================

set -e

echo ""
echo "=============================="
echo "  Настройка SWAP для Ubuntu"
echo "=============================="
echo ""

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Запусти скрипт от root: sudo bash setup_swap.sh"
  exit 1
fi

# Проверка — есть ли уже swap
EXISTING=$(swapon --show 2>/dev/null)
if [ -n "$EXISTING" ]; then
  echo "⚠️  Swap уже включён:"
  echo "$EXISTING"
  echo ""
  read -p "Продолжить и пересоздать? (y/n): " CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    echo "Отменено."
    exit 0
  fi
  swapoff /swapfile 2>/dev/null || true
fi

# Выбор размера
echo ""
echo "Выбери размер swap:"
echo "  1) 512MB"
echo "  2) 1GB"
echo "  3) 2GB"
echo "  4) Свой размер"
echo ""
read -p "Твой выбор (1-4): " CHOICE

case $CHOICE in
  1) SIZE="512M" ;;
  2) SIZE="1G" ;;
  3) SIZE="2G" ;;
  4)
    read -p "Введи размер (например 256M, 4G): " SIZE
    ;;
  *)
    echo "❌ Неверный выбор"
    exit 1
    ;;
esac

# Выбор swappiness
echo ""
echo "Выбери swappiness (как активно уходить в swap):"
echo "  1) 10  — редко (рекомендуется для сервера)"
echo "  2) 30  — умеренно"
echo "  3) 60  — по умолчанию в Ubuntu"
echo ""
read -p "Твой выбор (1-3): " SW_CHOICE

case $SW_CHOICE in
  1) SWAPPINESS=10 ;;
  2) SWAPPINESS=30 ;;
  3) SWAPPINESS=60 ;;
  *)
    echo "❌ Неверный выбор"
    exit 1
    ;;
esac

echo ""
echo "▶ Создаю swap-файл размером $SIZE..."
fallocate -l "$SIZE" /swapfile

echo "▶ Устанавливаю права (только root)..."
chmod 600 /swapfile

echo "▶ Форматирую как swap..."
mkswap /swapfile

echo "▶ Включаю swap..."
swapon /swapfile

echo "▶ Добавляю в /etc/fstab (автозапуск)..."
# Удаляем старую запись если есть
sed -i '/\/swapfile/d' /etc/fstab
echo '/swapfile none swap sw 0 0' >> /etc/fstab

echo "▶ Устанавливаю swappiness = $SWAPPINESS..."
sysctl vm.swappiness="$SWAPPINESS" > /dev/null
sed -i '/vm.swappiness/d' /etc/sysctl.conf
echo "vm.swappiness=$SWAPPINESS" >> /etc/sysctl.conf

echo ""
echo "=============================="
echo "  ✅ Готово! Результат:"
echo "=============================="
free -h
echo ""
echo "Swap будет работать после перезагрузки автоматически."
