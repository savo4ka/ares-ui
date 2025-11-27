# Инструкции по развертыванию Ares UI

## Разработка

### Быстрый старт

```bash
# Инициализация
make init

# Редактируйте .env (опционально для разработки)

# Запуск всех сервисов
make up

# Просмотр логов
make logs
```

Приложение доступно на:
- UI: http://localhost:3000
- API: http://localhost:8080

### Полезные команды

```bash
make help          # Список всех команд
make dev           # Локальная разработка (npm run dev)
make build         # Собрать Docker образ
make restart-ui    # Перезапустить UI
make logs-ui       # Логи UI
make check         # Проверить healthcheck
```

## Production Deployment

### Подготовка

1. **Создайте безопасные ключи**

```bash
# Генерация ENCRYPTION_KEY (32 символа)
openssl rand -hex 16

# Генерация REDIS_PASSWORD
openssl rand -base64 32
```

2. **Создайте production .env**

```bash
# .env
REDIS_PASSWORD=<сгенерированный-пароль>
ENCRYPTION_KEY=<сгенерированный-ключ-32-символа>
```

3. **Убедитесь, что .env в .gitignore**

```bash
# Проверьте, что .env не коммитится
cat .gitignore | grep .env
```

### Вариант 1: Docker Compose на сервере

#### Шаг 1: Подготовка сервера

```bash
# Обновите систему
sudo apt update && sudo apt upgrade -y

# Установите Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Установите Docker Compose
sudo apt install docker-compose-plugin -y

# Перезайдите для применения прав группы docker
```

#### Шаг 2: Клонирование и настройка

```bash
# Создайте директорию для проекта
mkdir -p /opt/ares
cd /opt/ares

# Скачайте необходимые файлы
wget https://raw.githubusercontent.com/savo4ka/ares-ui/main/docker-compose.prod.yml -O docker-compose.yml
wget https://raw.githubusercontent.com/savo4ka/ares-ui/main/.env.example

# Создайте .env с безопасными значениями
cp .env.example .env
nano .env  # Отредактируйте ENCRYPTION_KEY и REDIS_PASSWORD
```

#### Шаг 3: Запуск сервисов

```bash
# Запустите сервисы
docker-compose up -d

# Проверьте статус
docker-compose ps

# Проверьте логи
docker-compose logs -f
```

#### Шаг 4: Настройка Nginx с SSL

```bash
# Установите Nginx и Certbot
sudo apt install nginx certbot python3-certbot-nginx -y

# Создайте конфигурацию Nginx
sudo nano /etc/nginx/sites-available/ares
```

Содержимое файла:

```nginx
server {
    listen 80;
    server_name ares.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Увеличьте таймауты для длинных секретов
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

```bash
# Активируйте конфигурацию
sudo ln -s /etc/nginx/sites-available/ares /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Получите SSL сертификат
sudo certbot --nginx -d ares.yourdomain.com
```

#### Шаг 5: Автоматическое обновление

Создайте systemd service для автоматического запуска:

```bash
sudo nano /etc/systemd/system/ares.service
```

```ini
[Unit]
Description=Ares Secret Sharing Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/ares
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

```bash
# Включите автозапуск
sudo systemctl enable ares.service
sudo systemctl start ares.service
```

### Вариант 2: Kubernetes

#### Создайте secrets

```bash
kubectl create namespace ares

kubectl create secret generic ares-secrets \
  --from-literal=encryption-key=<ваш-ключ> \
  --from-literal=redis-password=<ваш-пароль> \
  -n ares
```

#### Примените манифесты

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ares-ui
  namespace: ares
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ares-ui
  template:
    metadata:
      labels:
        app: ares-ui
    spec:
      containers:
      - name: ares-ui
        image: ghcr.io/savo4ka/ares-ui:latest
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: "256Mi"
            cpu: "500m"
          requests:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: ares-ui
  namespace: ares
spec:
  selector:
    app: ares-ui
  ports:
  - port: 80
    targetPort: 80
```

## Мониторинг

### Healthchecks

```bash
# UI
curl http://localhost:3000/health

# API
curl http://localhost:8080/health

# Metrics (Prometheus)
curl http://localhost:8080/metrics
```

### Логи

```bash
# Docker Compose
docker-compose logs -f --tail=100 ares-ui
docker-compose logs -f --tail=100 ares-api

# Kubernetes
kubectl logs -f deployment/ares-ui -n ares
```

## Обновление

### Docker Compose

```bash
cd /opt/ares

# Скачайте новые образы
docker-compose pull

# Обновите сервисы
docker-compose up -d

# Проверьте
docker-compose ps
```

### Автоматическое обновление с Watchtower

```bash
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --interval 300 \
  ares-ui ares-api
```

## Бэкапы

### Бэкап Redis данных

```bash
# Создание бэкапа
docker-compose exec redis redis-cli --pass ${REDIS_PASSWORD} SAVE
docker cp ares-redis:/data/dump.rdb ./backup-$(date +%Y%m%d-%H%M%S).rdb

# Восстановление
docker cp backup.rdb ares-redis:/data/dump.rdb
docker-compose restart redis
```

## Безопасность

### Чеклист безопасности

- ✅ Используйте случайный 32-символьный ENCRYPTION_KEY
- ✅ Установите пароль для Redis
- ✅ Используйте HTTPS (SSL сертификат)
- ✅ Регулярно обновляйте Docker образы
- ✅ Ограничьте доступ к портам (используйте firewall)
- ✅ Настройте rate limiting на nginx
- ✅ Мониторьте логи на подозрительную активность
- ✅ Делайте регулярные бэкапы

### Firewall (UFW)

```bash
# Разрешите только необходимые порты
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

### Rate Limiting в Nginx

```nginx
# В http блоке
limit_req_zone $binary_remote_addr zone=ares_limit:10m rate=10r/s;

# В server блоке
location /api/secrets {
    limit_req zone=ares_limit burst=20 nodelay;
    proxy_pass http://127.0.0.1:3000;
}
```

## Troubleshooting

### Проблема: Контейнер не запускается

```bash
# Проверьте логи
docker-compose logs ares-ui

# Проверьте конфигурацию
docker-compose config

# Пересоберите образ
docker-compose build --no-cache ares-ui
```

### Проблема: API недоступен

```bash
# Проверьте healthcheck
docker-compose ps

# Проверьте сеть
docker network inspect ares_ares-network

# Проверьте подключение к Redis
docker-compose exec ares-api ping redis
```

### Проблема: Ошибки шифрования

```bash
# Убедитесь что ENCRYPTION_KEY установлен
docker-compose exec ares-api env | grep ENCRYPTION

# Длина должна быть 32 символа
echo -n "your-key" | wc -c
```

## Поддержка

- Issues: https://github.com/savo4ka/ares-ui/issues
- Backend: https://github.com/savo4ka/ares-api
