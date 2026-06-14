#!/bin/bash

if [ "$EUID" -eq 0 ]; then
	:
else
	echo "Необходимы права администратора"
	exit 1
fi

clear

echo "CRON"

echo ""
echo "Текущие задачи"
crontab -l 2>/dev/null || echo "(Нет задач)"

echo ""
echo "Добавить новую задачу? (y/n):"
read ADD_JOB

if [ "$ADD_JOB" != "y" ]; then
	exit 0
fi

echo ""
echo "Введите путь к скрипту:"
read SCRIPT_PATH

echo ""
echo "Введите расспиание:"
read CRON_TIME

echo ""
echo "Добавление задачи..."
(crontab -l 2>/dev/null; echo "$CRON_TIME $SCRIPT_PATH") | crontab -

echo ""
echo "Обновлённые задачи:"
crontab -l
