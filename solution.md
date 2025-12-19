# Решения тестового задания "DevOps-инженер (Яндекс Браузер для организаций)"

> **Для лучшего восприятия рекомендую посмотреть решения на GitHub, где файлы структурированы по отдельным заданиям:**  
> https://github.com/railgorail/yandex-crowd-devops-test

---

# Задание A1: "Собери и запусти" (Docker, Linux, CLI)

1. Создание директории проекта: test-project

```bash
mkdir test-project
cd test-project
```
2. index.html и Dockerfile
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Test App</title>
</head>
<body>
    <h1>Hello from Rail</h1>
</body>
</html>
```
```Dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
```
3. Сборка Docker-образа
```bash
docker build -t app:latest .
```
4. Запуск контейнера
```bash
docker run -d -p 8080:80 --name app-container app:latest
```
5. Проверка

по адресу http://localhost:8080/ отображается текст "Hello from Rail" -> все работает :)

6. С помощью Docker Compose 
```yaml
version: "3.8"

services:
  app-service:
    image: app:latest
    ports:
      - "8080:80"
```
запускаем командой

```bash
docker-compose up -d
```

7. Вопрос для размышления

Самый простой способ - "примонтировать" volume

```bash
docker run -p 8080:80 \
  -v $(pwd)/index.html:/usr/share/nginx/html/index.html \
  nginx:alpine
```


---

# Задание B1: "Простой скрипт-помощник" (Bash)

Скрипт `clean_old_logs.sh` для очистки старых лог-файлов.

### Использование

```bash
./clean_old_logs.sh /path/to/logs 30
```
### Пример работы

```bash
$ ./clean_old_logs.sh /var/log 7
Найдены следующие файлы старше 7 дней:
/var/log/app.log
/var/log/error.log
Удалить эти файлы? (y/n): y
Удаление файлов...
/var/log/app.log удален
/var/log/error.log удален
Готово!
```

### Исходный код скрипта clean_old_logs.sh

```bash
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

```


---

# Задание B2: "Маленькая проблема в Git" (Git)

### Решение
```bash
# Сохраняем незакоммиченные изменения
git stash push -m "WIP: in progress"

# Переключаемся на main
git checkout main

# Делаем изменения в main ...
git add .
git commit -m "fix: critical bug"
git push origin main

# Возвращаемся на feature/junior-task
git checkout feature/junior-task

# Восстанавливаем изменения
git stash pop

# Переименовывeaм последний коммит
git commit --amend -m "feat: smth"
git push --force-with-lease origin feature/junior-task
```


---

# Задание B3: "Объясни концепцию" (Понимание CI/CD)

### Схема автоматической сборки Docker-образа при пуше в ветку main

Когда разработчик пушит код в ветку `main` в GitLab/GitHub, запускается CI/CD pipeline следующего вида:

### Процесс по шагам(этапам)
Если на любом этапе происходит ошибка -> отправка уведомления о провале в Telegram -> завершение pipeline с ошибкой.
```md
Push в main
|
Запуск CI/CD Pipeline (автоматический триггер)
|
Checkout кода
|
Запуск тестов
| (если тесты прошли)
Сборка Docker-образа
|
Теггирование образа (например, latest, commit SHA)
|
Push образа в Docker Hub
| (если push успешен)
Уведомление в Telegram (успех)
|
Завершение pipeline
```



### Подробное описание этапов

#### Этап 1: Push в ветку main
Разработчик выполняет `git push origin main`, что вызывает webhook в GitLab/GitHub.

#### Этап 2: Запуск CI/CD Pipeline
CI/CD система (GitLab CI, GitHub Actions) обнаруживает push в `main` и автоматически запускает pipeline, определенный в `.gitlab-ci.yml` или `.github/workflows/*.yml`.

#### Этап 3: Checkout кода
CI/CD система клонирует репозиторий в чистую среду выполнения (runner) на нужную ветку/коммит.

#### Этап 4: Запуск линтеров и множества тестов
Выполняются различные тесты (порядок запусков имеет значение):
- Линтинг кода
- Unit-тесты
- Integration-тесты
- Проверка безопасности

Если тесты не прошли -> отправка уведомления о провале -> остановка pipeline.

#### Этап 5: Сборка Docker-образа
Если тесты прошли успешно, выполняется:
```bash
docker build -t my-app:latest -t my-app:$CI_COMMIT_SHA .
```

Где `$CI_COMMIT_SHA` - хэш коммита для уникальной версии образа.

#### Этап 6: Тегирование образа
Образ тегируется несколькими тегами:
- `latest` - для последней версии
- `$CI_COMMIT_SHA` - для конкретного коммита
- Возможно, `$CI_COMMIT_TAG` или версия из проекта

#### Этап 7: Push образа в Docker Hub
Выполняется авторизация в Docker Hub и push образа:
```bash
docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
docker push my-app:latest
docker push my-app:$CI_COMMIT_SHA
```

#### Этап 8: Уведомление в Telegram
После успешного push отправляется уведомление в Telegram через бота:
- Успех: "УСПЕХ: Build успешно завершен. Образ my-app:$CI_COMMIT_SHA отправлен в Docker Hub"
- Провал: "ПРОВАЛ: Build провален на этапе [название этапа]. Ошибка: [детали]"

#### Этап 9: Завершение pipeline
Pipeline завершается с соответствующим статусом (success/failed).

### Необходимые секреты/переменные окружения
- `DOCKER_USERNAME` / `DOCKER_PASSWORD` 
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

### Пример конфигурации GitLab CI (.gitlab-ci.yml)
```yaml
stages:
  - test
  - build
  - deploy
  - notify

variables:
  DOCKER_IMAGE: my-app
  DOCKER_REGISTRY: docker.io
  DOCKER_USERNAME: $CI_REGISTRY_USER

before_script:
  - docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $DOCKER_REGISTRY

test:
  stage: test
  image: node:18
  script:
    - npm install
    - npm run lint
    - npm test
  only:
    - main

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $DOCKER_REGISTRY/$DOCKER_USERNAME/$DOCKER_IMAGE:latest .
    - docker build -t $DOCKER_REGISTRY/$DOCKER_USERNAME/$DOCKER_IMAGE:$CI_COMMIT_SHA .
    - docker push $DOCKER_REGISTRY/$DOCKER_USERNAME/$DOCKER_IMAGE:latest
    - docker push $DOCKER_REGISTRY/$DOCKER_USERNAME/$DOCKER_IMAGE:$CI_COMMIT_SHA
  only:
    - main
  dependencies:
    - test

notify_success:
  stage: notify
  image: alpine:latest
  script:
    - apk add --no-cache curl
    - |
      curl -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=УСПЕХ: Build успешно завершен. Образ $DOCKER_IMAGE:$CI_COMMIT_SHA отправлен в Docker Hub"
  only:
    - main
  when: on_success

notify_failure:
  stage: notify
  image: alpine:latest
  script:
    - apk add --no-cache curl
    - |
      curl -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=ПРОВАЛ: Build провален. Проверьте логи pipeline: $CI_PIPELINE_URL"
  only:
    - main
  when: on_failure
```

### Пример конфигурации GitHub Actions (.github/workflows/build.yml)

```yaml
name: Build and Push Docker Image

on:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm run lint
      - run: npm test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            my-app:latest
            my-app:${{ github.sha }}
      
      - name: Send Telegram notification (success)
        if: success()
        uses: appleboy/telegram-action@master
        with:
          to: ${{ secrets.TELEGRAM_CHAT_ID }}
          token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          message: |
            УСПЕХ: Build успешно завершен
            Образ my-app:${{ github.sha }} отправлен в Docker Hub
      
      - name: Send Telegram notification (failure)
        if: failure()
        uses: appleboy/telegram-action@master
        with:
          to: ${{ secrets.TELEGRAM_CHAT_ID }}
          token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          message: |
            ПРОВАЛ: Build провален
            Проверьте логи: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
```



