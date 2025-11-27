# Ares UI

Фронтенд приложение для сервиса безопасной передачи секретов.

## Описание

Ares - это сервис для безопасной передачи конфиденциальной информации (паролей, учетных данных и т.д.). Каждый секрет:
- Шифруется на стороне сервера (AES-128-CBC)
- Может быть прочитан только один раз
- Автоматически удаляется после истечения срока действия (24, 48 или 72 часа)

## Технологии

- Vue.js 3 (Composition API)
- Vue Router 4
- Axios
- Vite

## Установка и запуск

### Вариант 1: Docker Compose (рекомендуется)

Самый простой способ запустить весь стек (UI + API + Redis):

```bash
# Скопируйте пример переменных окружения
cp .env.example .env

# Отредактируйте .env и установите ENCRYPTION_KEY (для production!)

# Запустите все сервисы
docker-compose up -d

# Приложение будет доступно на http://localhost:3000
```

Сервисы:
- **UI**: http://localhost:3000
- **API**: http://localhost:8080
- **Redis**: localhost:6379

Остановка:
```bash
docker-compose down
```

Просмотр логов:
```bash
docker-compose logs -f ares-ui
docker-compose logs -f ares-api
```

### Вариант 2: Только UI в Docker

Если бэкэнд уже запущен отдельно:

```bash
# Сборка образа
docker build -t ares-ui:latest .

# Запуск контейнера
docker run -d -p 3000:80 --name ares-ui ares-ui:latest
```

### Вариант 3: Локальная разработка

```bash
# Установка зависимостей
npm install

# Запуск dev-сервера
npm run dev
```

Приложение будет доступно по адресу: http://localhost:3000

### Сборка для продакшена

```bash
npm run build
```

## Конфигурация

### Локальная разработка

По умолчанию фронтенд настроен на проксирование API запросов к `http://localhost:8080`.

Для изменения адреса бэкэнда отредактируйте файл `vite.config.js`:

```javascript
proxy: {
  '/api': {
    target: 'http://your-backend-url:port',
    changeOrigin: true
  }
}
```

### Docker

В Docker-окружении проксирование настроено в `nginx.conf`. API запросы автоматически проксируются к сервису `ares-api:8080`.

### Переменные окружения

Создайте файл `.env` на основе `.env.example`:

```bash
# Redis Configuration
REDIS_PASSWORD=
REDIS_DB=0

# Encryption Key (32 characters for AES-256)
# ВАЖНО: Для production ОБЯЗАТЕЛЬНО измените этот ключ!
ENCRYPTION_KEY=abcdef0123456789abcdef0123456789
```

**Важно для production:**
- Сгенерируйте случайный 32-символьный ключ для `ENCRYPTION_KEY`
- Установите пароль для Redis в `REDIS_PASSWORD`
- Используйте HTTPS для публичного доступа

## Структура проекта

```
ares-ui/
├── public/              # Статические файлы
├── src/
│   ├── assets/         # Ресурсы (изображения, шрифты)
│   ├── components/     # Переиспользуемые компоненты
│   ├── composables/    # Композиционные функции
│   │   └── useTheme.js # Управление темой
│   ├── services/       # API сервисы
│   │   └── api.js      # Интеграция с бэкэндом
│   ├── views/          # Страницы
│   │   ├── CreateSecret.vue  # Создание секрета
│   │   └── ViewSecret.vue    # Просмотр секрета
│   ├── router/         # Настройка маршрутизации
│   ├── App.vue         # Корневой компонент
│   ├── main.js         # Точка входа
│   └── style.css       # Глобальные стили
├── index.html
├── package.json
└── vite.config.js
```

## Функционал

### Создание секрета
- Ввод секретного сообщения
- Выбор времени жизни (24, 48 или 72 часа)
- Генерация уникальной ссылки
- Копирование ссылки в буфер обмена
- Скрытие/показ сгенерированной ссылки

### Просмотр секрета
- Отображение секрета (только один раз)
- Копирование содержимого секрета
- Предупреждение о том, что секрет был прочитан
- Отображение даты создания и истечения

### Общие возможности
- Переключение между светлой и темной темой
- Сохранение выбранной темы в localStorage
- Автоматическое определение темы системы
- Адаптивный дизайн

## Интеграция с бэкэндом

Бэкэнд API: [ares-api](https://github.com/savo4ka/ares-api)

### Используемые эндпоинты:

**POST /api/secrets**
```json
{
  "content": "секретное сообщение",
  "expiration_hours": 72
}
```

**GET /api/secrets/:id**
```json
{
  "content": "секретное сообщение",
  "created_at": "2024-01-01T00:00:00Z",
  "expires_at": "2024-01-04T00:00:00Z"
}
```

## Дизайн

Дизайн вдохновлен цветовой палитрой Claude.ai:
- Акцентный цвет: оранжевый (#D97706, #F59E0B)
- Поддержка светлой и темной темы
- Минималистичный и понятный интерфейс

## CI/CD

Проект настроен на автоматическую сборку и публикацию Docker образов в GitHub Container Registry.

### GitHub Actions

При каждом push в `main` или создании тега версии автоматически:
1. Собирается Docker образ
2. Публикуется в `ghcr.io/savo4ka/ares-ui`
3. Создается аттестация для образа

### Использование опубликованного образа

```bash
# Последняя версия
docker pull ghcr.io/savo4ka/ares-ui:latest

# Конкретная версия
docker pull ghcr.io/savo4ka/ares-ui:v1.0.0
```

### Создание релиза

```bash
# Создайте тег версии
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions автоматически создаст и опубликует образ
```

## Production Deployment

### Docker Compose в Production

1. Создайте `.env` файл с безопасными значениями:
```bash
REDIS_PASSWORD=<strong-random-password>
ENCRYPTION_KEY=<32-character-random-key>
```

2. Используйте опубликованный образ:
```yaml
ares-ui:
  image: ghcr.io/savo4ka/ares-ui:latest
  # ... остальная конфигурация
```

3. Настройте reverse proxy (nginx, traefik) с SSL:
```nginx
server {
    listen 443 ssl http2;
    server_name ares.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Разработка

### Структура файлов для Docker

```
ares-ui/
├── .github/
│   └── workflows/
│       └── docker-publish.yml  # CI/CD workflow
├── Dockerfile                  # Multi-stage Docker build
├── docker-compose.yml          # Полный стек для разработки
├── nginx.conf                  # Production nginx конфигурация
├── .dockerignore              # Исключения для Docker build
└── .env.example               # Пример переменных окружения
```

### Полезные команды

```bash
# Пересборка образа
docker-compose build ares-ui

# Запуск только UI
docker-compose up ares-ui

# Просмотр логов в реальном времени
docker-compose logs -f

# Остановка и удаление контейнеров
docker-compose down -v

# Проверка здоровья контейнеров
docker-compose ps
```

## Лицензия

MIT
