.PHONY: help dev build up down logs clean restart ps

help: ## Показать справку
	@echo "Доступные команды:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

dev: ## Запустить dev-сервер (npm run dev)
	npm run dev

install: ## Установить зависимости
	npm install

build-local: ## Собрать приложение локально
	npm run build

# Docker команды

build: ## Собрать Docker образ
	docker-compose build ares-ui

up: ## Запустить все сервисы в фоне
	docker-compose up -d

down: ## Остановить все сервисы
	docker-compose down

logs: ## Показать логи всех сервисов
	docker-compose logs -f

logs-ui: ## Показать логи UI
	docker-compose logs -f ares-ui

logs-api: ## Показать логи API
	docker-compose logs -f ares-api

logs-redis: ## Показать логи Redis
	docker-compose logs -f redis

restart: ## Перезапустить все сервисы
	docker-compose restart

restart-ui: ## Перезапустить UI
	docker-compose restart ares-ui

ps: ## Показать статус контейнеров
	docker-compose ps

clean: ## Остановить и удалить все контейнеры, volumes
	docker-compose down -v
	rm -rf dist node_modules

rebuild: ## Пересобрать и перезапустить UI
	docker-compose build ares-ui
	docker-compose up -d ares-ui

shell-ui: ## Войти в shell контейнера UI
	docker-compose exec ares-ui sh

shell-api: ## Войти в shell контейнера API
	docker-compose exec ares-api sh

shell-redis: ## Войти в Redis CLI
	docker-compose exec redis redis-cli

# Полезные команды

check: ## Проверить healthcheck всех сервисов
	@echo "=== Проверка здоровья сервисов ==="
	@docker-compose ps
	@echo "\n=== UI health ==="
	@curl -f http://localhost:3000/health || echo "UI недоступен"
	@echo "\n=== API health ==="
	@curl -f http://localhost:8080/health || echo "API недоступен"

init: ## Первый запуск проекта
	@echo "=== Инициализация проекта ==="
	cp .env.example .env
	@echo "✓ Создан .env файл"
	@echo "⚠️  ВАЖНО: Отредактируйте .env и установите безопасный ENCRYPTION_KEY"
	@echo ""
	@echo "Запустите 'make up' для старта сервисов"
