#!/bin/bash

# Проверяем права root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[ОШИБКА] Пожалуйста, запустите скрипт с правами sudo: sudo ./docker_manager.sh\e[0m"
  exit 1
fi

# Проверяем, установлен ли Docker
if ! command -v docker &> /dev/null; then
    echo -e "\e[31m[ОШИБКА] Docker не найден в системе!\e[0m"
    exit 1
fi

print_section() {
    echo -e "\n\e[34m==================================================\e[0m"
    echo -e "\e[1;32m  $1\e[0m"
    echo -e "\e[34m==================================================\e[0m"
}

# ==============================================================================
# ЧАСТЬ 1: ПРОВЕРКА СТАТУСА КОНТЕЙНЕРОВ
# ==============================================================================
print_section "ПРОВЕРКА СТАТУСА КОНТЕЙНЕРОВ"

total_containers=$(docker ps -a --format '{{.Names}}\t{{.Status}}')

if [ -z "$total_containers" ]; then
    echo -e "\e[33m[ИНФО] В системе нет ни одного созданного контейнера.\e[0m"
else
    has_failed=0
    echo -e "\e[1mАнализ состояния:\e[0m"
    
    while IFS=$'\t' read -r name status; do
        if [[ "$status" =~ ^Up ]]; then
            echo -e "  Container \e[32m$name\e[0m: \e[32mЗАПУЩЕН\e[0m ($status)"
        else
            echo -e "  Container \e[31m$name\e[0m: \e[31mНЕ РАБОТАЕТ\e[0m ($status)"
            has_failed=1
        fi
    done <<< "$total_containers"
    
    echo "--------------------------------------------------"
    if [ $has_failed -eq 0 ]; then
        echo -e "\e[1;32m[ОТЛИЧНО] Все контейнеры работают стабильно!\e[0m"
    else
        echo -e "\e[1;31m[ВНИМАНИЕ] Обнаружены остановленные или упавшие контейнеры!\e[0m"
    fi
fi

# ==============================================================================
# ЧАСТЬ 2: БЕЗОПАСНАЯ ОЧИСТКА DOCKER
# ==============================================================================
print_section "ОЧИСТКА НЕИСПОЛЬЗУЕМЫХ РЕСУРСОВ DOCKER"

echo "Запуск генеральной уборки Docker..."

exited_containers=$(docker ps -a -q -f status=exited)
dangling_images=$(docker images -f "dangling=true" -q)

if [ -z "$exited_containers" ] && [ -z "$dangling_images" ]; then
    echo -e "Проверка кэша и слоев... \e[33m[УЖЕ ПУСТО]\e[0m"
    docker system prune -f --volumes >/dev/null 2>&1
else
    echo -e "\e[2mСвободное место на диске до очистки:\e[0m"
    df -h / | awk 'NR==2 {print "  До: " $4 " свободно"}'

    docker system prune -a -f --volumes >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "Очистка кэша, контейнеров и образов... \e[32m[УСПЕШНО]\e[0m"
        echo -e "\e[2mСвободное место на диске после очистки:\e[0m"
        df -h / | awk 'NR==2 {print "  После: " $4 " свободно"}'
    else
        echo -e "Очистка... \e[31m[ОШИБКА]\e[0m"
    fi
fi

# ==============================================================================
# ФИНАЛ СКРИПТА
# ==============================================================================
echo ""
echo -e "\e[34m==================================================\e[0m"
echo -e "\e[1;32m  ОЧИСТКА ЗАВЕРШЕНА\e[0m"
echo -e "\e[34m==================================================\e[0m"
echo ""
