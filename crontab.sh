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
while true; do
	read -r -p "Добавить новую задачу? (y/n): " ADD_JOB

	if [ -z "$ADD_JOB" ]; then
        	echo "Ввод не может быть пустым."
		echo ""
		continue
	fi

	if [ "$ADD_JOB" = "y" ] || [ "$ADD_JOB" = "Y" ]; then
		break
	elif [ "$ADD_JOB" = "n" ] || [ "$ADD_JOB" = "N" ]; then
		exit 0
	else
		echo "Неверный ввод."
		echo ""
	fi
done

#Путь к скрипту
echo ""
while true; do
	read -e -r -p "Введите полный путь к скрипту: " SCRIPT_PATH

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
	read -r -p "Введите расписание (пример: 0 9 * * *): " CRON_TIME
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

#Логирование
echo ""
while true; do
	read -r -p  "Включить логирование: (y/n): " ENABLE_LOG
	if [ -z "$ENABLE_LOG" ]; then
		echo "Ввод не может быть пустым."
		echo ""
		continue
	fi

	if [ "$ENABLE_LOG" = "y" ] || [ "$ENABLE_LOG" = "Y" ]; then
                SCRIPT_NAME=$(basename "$SCRIPT_PATH")
                SCRIPT_NAME="${SCRIPT_NAME%.sh}"
                LOG_DIR="/var/log/cron_jobs/$SCRIPT_NAME"

                mkdir -p "$LOG_DIR"
                chmod 755 "$LOG_DIR"

                LOG_FILE="$LOG_DIR/$SCRIPT_NAME.log"
                CRON_COMMAND="$SCRIPT_PATH >> $LOG_FILE 2>&1"

                echo -e "\nЛоги будут сохраняться в: $LOG_FILE"
                break
        elif [ "$ENABLE_LOG" = "n" ] || [ "$ENABLE_LOG" = "N" ]; then
                CRON_COMMAND="$SCRIPT_PATH"
                break
        else
                echo "Неверный ввод."
                echo ""
        fi
done
