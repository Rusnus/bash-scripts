#!/bin/bash

if [ "$EUID" -eq 0 ]; then
        :
else
        echo "Необходимы права администратора."
        exit 1
fi

clear
echo "CRON"

#Текущие задачи
echo -e "\nТекущие задачи:"
CURRENT_CRON=$(crontab -l 2>/dev/null)
if [ -z "$CURRENT_CRON" ]; then
        echo "Нет активных задач"
else
        echo "$CURRENT_CRON"
fi

#Добавление задачи
echo ""
read -p "Добавить новую задачу? (y/n): " ADD_JOB
if [ "$ADD_JOB" != "y" ] && [ "$ADD_JOB" != "Y" ]; then
        exit 0
fi

#Путь к скрипту
echo ""
while true; do
	read -e -r -p "Введите полный путь к скрипту:" SCRIPT_PATH

	if [ -f "$SCRIPT_PATH" ]; then
		break
	else 
		echo "Файл не найден."
		echo ""
	fi
done

#Расписание задачи
echo ""
while true; do
	read -r -p "Введите рассписание (пример: 0 9 * * *):" CRON_TIME
	FIELDS_COUNT=$(echo "$CRON_TIME" | awk '{print NF}')

	if [ "$FIELDS_COUNT" -ne 5 ]; then
		echo "Ошибка: расписание должно состоять из 5-ти элементов(минута час день месяц день_недели)"
		echo ""
	elif [[ "$CRON_TIME" =~ [^0-9\ \*\,/\-] ]]; then
		echo "Ошибка: расписание не должно содержать буквы и не допустимые знаки."
		echo ""
	else
		break
	fi
done
