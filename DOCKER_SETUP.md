# Docker Setup - Краткое руководство

## Созданные файлы

### Docker конфигурация
- `Dockerfile` - Multi-stage сборка (Node.js + Nginx)
- `docker-compose.yml` - Для разработки (UI + API + Redis)
- `docker-compose.prod.yml` - Для production с ограничениями
- `.dockerignore` - Исключения при сборке
- `nginx.conf` - Production конфигурация nginx с проксированием API

### CI/CD
- `.github/workflows/docker-publish.yml` - Автоматическая сборка и публикация в GHCR

### Вспомогательные файлы
- `.env.example` - Пример переменных окружения
- `Makefile` - Удобные команды для работы
- `DEPLOYMENT.md` - Подробное руководство по развертыванию

## Быстрый старт

```bash
# 1. Инициализация
make init

# 2. Запуск всех сервисов
make up

# 3. Проверка
make check
```

Приложение доступно на http://localhost:3000

## Основные команды

```bash
make help          # Список всех команд
make up            # Запустить сервисы
make down          # Остановить сервисы
make logs          # Показать логи
make logs-ui       # Логи UI
make logs-api      # Логи API
make restart       # Перезапустить
make clean         # Очистить все
make check         # Проверить healthcheck
```

## Production развертывание

См. подробности в [DEPLOYMENT.md](DEPLOYMENT.md)

## CI/CD

При push в `main` или создании тега:
1. Автоматически собирается Docker образ
2. Публикуется в `ghcr.io/savo4ka/ares-ui`
3. Создается аттестация образа

### Создание релиза

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Архитектура

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTP
       ▼
┌─────────────┐
│  Nginx:80   │ (ares-ui)
│  Static +   │
│  /api proxy │
└──────┬──────┘
       │ proxy /api
       ▼
┌─────────────┐
│ API:8080    │ (ares-api)
│  Go Backend │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Redis:6379  │ (redis)
│  Data Store │
└─────────────┘
```

## Порты

- **3000** - UI (nginx)
- **8080** - API (внутренний)
- **6379** - Redis (внутренний)

## Переменные окружения

| Переменная | Описание | Дефолт | Production |
|-----------|----------|--------|------------|
| ENCRYPTION_KEY | Ключ шифрования (32 символа) | `abcd...` | ⚠️ ОБЯЗАТЕЛЬНО изменить |
| REDIS_PASSWORD | Пароль Redis | пусто | ⚠️ ОБЯЗАТЕЛЬНО установить |
| REDIS_DB | Номер БД Redis | 0 | 0 |

## Безопасность

### ⚠️ ВАЖНО для production:

1. **Измените ENCRYPTION_KEY**
   ```bash
   openssl rand -hex 16
   ```

2. **Установите REDIS_PASSWORD**
   ```bash
   openssl rand -base64 32
   ```

3. **Используйте HTTPS** с валидным SSL сертификатом

4. **Настройте firewall**
   ```bash
   sudo ufw allow http
   sudo ufw allow https
   ```

## Healthcheck endpoints

- UI: `http://localhost:3000/health`
- API: `http://localhost:8080/health`
- Metrics: `http://localhost:8080/metrics`

## Обновление

```bash
# Скачать новые образы
docker-compose pull

# Обновить сервисы
docker-compose up -d
```

## Troubleshooting

### Контейнер не запускается

```bash
docker-compose logs ares-ui
docker-compose ps
```

### API недоступен

```bash
docker-compose exec ares-ui wget -O- http://ares-api:8080/health
```

### Проблемы с сетью

```bash
docker network inspect ares_ares-network
```

## Дополнительная информация

- [README.md](README.md) - Общая информация о проекте
- [DEPLOYMENT.md](DEPLOYMENT.md) - Детальное руководство по развертыванию
- [Backend repo](https://github.com/savo4ka/ares-api) - Репозиторий бэкенда
