#!/bin/bash

if [ "$EUID" -eq 0 ]; then
        :
else
        echo "Необходимы права администратора."
        exit 1
fi

clear
echo "CRON"
echo -e "\nТекущие задачи:"
CURRENT_CRON=$(crontab -l 2>/dev/null)
if [ -z "$CURRENT_CRON" ]; then
        echo "Нет активных задач"
else
        echo "$CURRENT_CRON"
fi

echo ""
read -p "Добавить новую задачу? (y/n): " ADD_JOB
if [ "$ADD_JOB" != "y" ] && [ "$ADD_JOB" != "Y" ]; then
        exit 0
fi
