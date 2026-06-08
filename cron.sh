#!/bin/bash

if [ "$EUID" -eq 0 ]; then
	:
else
	echo "Необходимы права администратора"
	exit 1
fi

clear

echo "CRON"
