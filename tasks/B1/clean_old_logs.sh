#!/bin/bash

# Проверка наличия аргументов
if [ $# -ne 2 ]; then
    echo "Использование: $0 <путь_к_директории> <количество_дней>"
    echo "Пример: $0 /var/log 7"
    exit 1
fi

LOG_DIR="$1"
DAYS="$2"

# Проверка существования директории
if [ ! -d "$LOG_DIR" ]; then
    echo "Ошибка: Директория '$LOG_DIR' не существует"
    exit 1
fi

# Проверка, что DAYS - натуральное число или 0
if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
    echo "Ошибка: Количество дней должно быть натуральным числом или 0"
    exit 1
fi

# Поиск файлов .log старше N дней
if [[ "$DAYS" -eq 0 ]]; then
    OLD_FILES=$(find "$LOG_DIR" -type f -name "*.log" 2>/dev/null)
else
    OLD_FILES=$(find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS" 2>/dev/null)
fi

# Проверка, найдены ли файлы
if [ -z "$OLD_FILES" ]; then
    echo "Файлы .log старше $DAYS дней не найдены в директории '$LOG_DIR'"
    exit 0
fi

# Вывод списка найденных файлов
echo "Найдены следующие файлы старше $DAYS дней:"
echo "$OLD_FILES" | while read -r file; do
    echo "  $file"
done

# Запрос подтверждения
echo ""
read -p "Удалить эти файлы? (y/n): " answer
echo ""

if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    echo "Удаление файлов..."
    echo "$OLD_FILES" | while read -r file; do
        if rm "$file" 2>/dev/null; then
            echo "  $file удален"
        else
            echo "  Ошибка при удалении: $file"
        fi
    done
    echo "Готово!"
else
    echo "Операция отменена"
    exit 0
fi

