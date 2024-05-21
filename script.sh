#!/bin/bash

# Функция для вывода справки
function show_help {
    echo "Использование: $0 [опции]"
    echo "Опции:"
    echo "  -u, --users         Выводит перечень пользователей и их домашних директорий"
    echo "  -p, --processes     Выводит перечень запущенных процессов"
    echo "  -h, --help          Выводит эту справку"
    echo "  -l PATH, --log PATH Записывает вывод в файл по заданному пути"
    echo "  -e PATH, --errors PATH Записывает ошибки в файл по заданному пути"
    exit 0
}

# Функция для вывода пользователей
function list_users {
    awk -F: '{ print $1 ": " $6 }' /etc/passwd | sort
}

# Функция для вывода процессов
function list_processes {
    ps -e --sort pid
}

# Инициализация переменных для логов и ошибок
LOG_PATH=""
ERROR_PATH=""

# Обработка аргументов командной строки
while getopts ":uphl:e:-:" opt; do
    case $opt in
        u)
            ACTION="users"
            ;;
        p)
            ACTION="processes"
            ;;
        h)
            show_help
            ;;
        l)
            LOG_PATH=$OPTARG
            ;;
        e)
            ERROR_PATH=$OPTARG
            ;;
        -)
            case "${OPTARG}" in
                users)
                    ACTION="users"
                    ;;
                processes)
                    ACTION="processes"
                    ;;
                help)
                    show_help
                    ;;
                log)
                    LOG_PATH="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                errors)
                    ERROR_PATH="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                *)
                    echo "Неверный аргумент: --${OPTARG}" >&2
                    show_help
                    ;;
            esac
            ;;
        \?)
            echo "Неверный опция: -$OPTARG" >&2
            show_help
            ;;
        :)
            echo "Опция -$OPTARG требует аргумент" >&2
            show_help
            ;;
    esac
done

# Проверка доступности путей для логов и ошибок
if [ -n "$LOG_PATH" ] && [ ! -w "$LOG_PATH" ]; then
    echo "Невозможно записать в файл лога: $LOG_PATH" >&2
    exit 1
fi

if [ -n "$ERROR_PATH" ] && [ ! -w "$ERROR_PATH" ]; then
    echo "Невозможно записать в файл ошибок: $ERROR_PATH" >&2
    exit 1
fi

# Выполнение действия и вывод результатов
case $ACTION in
    users)
        OUTPUT=$(list_users 2>&1)
        ;;
    processes)
        OUTPUT=$(list_processes 2>&1)
        ;;
    *)
        show_help
        ;;
esac

# Запись вывода в файл или на экран
if [ -n "$LOG_PATH" ]; then
    echo "$OUTPUT" > "$LOG_PATH"
else
    echo "$OUTPUT"
fi

# Запись ошибок в файл или на экран
if [ -n "$ERROR_PATH" ]; then
    echo "$OUTPUT" > "$ERROR_PATH"
else
    echo "$OUTPUT" >&2
fi
