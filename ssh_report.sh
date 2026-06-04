#!/bin/bash

clear

echo "SSH отчёт"

echo "Успешные входы"
journalctl | grep -i sshd | grep -i "accepted" | tail -10

echo ""
echo "Неуспешные входы"
journalctl | grep -i sshd | grep -i "failed password" | tail -10

echo ""
echo "Открытые порты"
ss -tlnp | grep LISTEN | awk '{print $4, $6}'

echo""
echo "Заблокированные IP (fail2ban)"
fail2ban-client status sshd | grep "Banned IP list" -A 10

echo""
echo "Список пользователей"
getent passwd | awk -F: '{print $1}'
