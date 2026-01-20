# Ares UI

Фронтенд приложение для сервиса безопасной передачи секретов.

## Описание

Ares - это сервис для безопасной передачи конфиденциальной информации (паролей, учетных данных и т.д.). Каждый секрет:
- Шифруется на стороне сервера (AES-256-GCM)
- Может быть прочитан только один раз
- Автоматически удаляется после истечения срока действия (24, 48 или 72 часа)

## Технологии

- Vue.js 3 (Composition API)
- Vue Router 4
- Axios
- Vite

## Установка и запуск

### Вариант 1: Только UI в Docker

Если бэкэнд уже запущен отдельно:

```bash
# Сборка образа
docker build -t ares-ui:latest .

# Запуск контейнера
docker run -d -p 3000:80 --name ares-ui ares-ui:latest
```

### Вариант 2: Локальная разработка

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

Дизайн:
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

1. Создайте сертификаты и укажите путь к ним в `docker-compose.yml`:
```yaml
# ... остальная конфигурация
volumes:
  - /path/to/cert/fullchain.pem:/etc/nginx/ssl/fullchain.pem:ro
  - /path/to/key/privkey.key:/etc/nginx/ssl/privkey.key:ro
# ... остальная конфигурация
```

2. Укажите ваш домен (если отсутствует, то IP-адрес) в nginx.conf
```nginx
# ... остальная конфигурация
server_name YOUR_DOMAIN;
# ... остальная конфигурация
```

3. Если backend находит на другой ноде, то изменить проксирование в `vite.config.js`:
```javascript
proxy: {
  '/api': {
    target: 'http://your-backend-url:port',
    changeOrigin: true
  }
}
```

4. Запустите docker compose:
```bash
docker compose up -d
```

5. Посмотреть логи и убедиться в корректности запуска:
```bash
docker compose logs -f
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

## Контакты

Email: praslov007@gmail.com
