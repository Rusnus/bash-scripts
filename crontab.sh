#!/bin/bash

if [ "$EUID" -ne 0 ]; then
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

#Путь к скрипту и проверка на исполняемость
echo ""
while true; do
	read -e -r -p "Введите полный путь к скрипту: " SCRIPT_PATH

	if [ -f "$SCRIPT_PATH" ]; then
		if [ ! -x "$SCRIPT_PATH" ]; then
			read -r -p "Файл не исполняемый. Выдать права? (y/n): " FIX_EXECUT
				if [ "$FIX_EXECUT" = "y" ]; then
					chmod +x "$SCRIPT_PATH"
				else 
					echo "Внимание! Скрипт может не запуститься без прав на выполнение."
				fi
		fi
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
		continue
	fi

	if [[ "$CRON_TIME" =~ [^0-9\ \*\,/\-] ]]; then
		echo "Ошибка: расписание не должно содержать буквы и не допустимые знаки."
		echo ""
		continue
	fi

	MIN=$(echo "$CRON_TIME" | awk '{print $1}')
   	HRS=$(echo "$CRON_TIME" | awk '{print $2}')
    	DAY=$(echo "$CRON_TIME" | awk '{print $3}')
	MON=$(echo "$CRON_TIME" | awk '{print $4}')
    	DOW=$(echo "$CRON_TIME" | awk '{print $5}')

    	VALID=true

	check_range() {
		local val=$1 min=$2 max=$3 name=$4
        	if [[ "$val" != "*" ]] && [[ "$val" =~ ^[0-9]+$ ]]; then
            		if [ "$val" -lt "$min" ] || [ "$val" -gt "$max" ]; then
                		echo "Ошибка: $name от $min до $max."
                		echo ""
                		VALID=false
            		fi
        	fi
    	}

	check_range "$MIN" 0 59 "минута"
    	check_range "$HRS" 0 23 "час"
    	check_range "$DAY" 1 31 "день"
    	check_range "$MON" 1 12 "месяц"
    	check_range "$DOW" 0 7  "день недели"

    	if [ "$VALID" = true ]; then
        	break
    	fi
done

#Логирование
echo ""
while true; do
	read -r -p  "Включить логирование? (y/n): " ENABLE_LOG
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
                CRON_COMMAND="\"$SCRIPT_PATH\" >> \"$LOG_FILE\" 2>&1"

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

echo -e "\nДобавление задачи..."

#Безопасное добавление
TMP_CRON=$(mktemp)
trap "rm -f '$TMP_CRON'" EXIT
if [ -n "$CURRENT_CRON" ]; then
	echo "$CURRENT_CRON" >> "$TMP_CRON"
fi
echo "$CRON_TIME $CRON_COMMAND" >> "$TMP_CRON"

#Отправка
if crontab "$TMP_CRON"; then
	echo "Задача успешно добавлена."
else
	echo "Ошибка при добавлении задачи."
fi

echo -e "\nОбновлённый список задач:"
crontab -l
