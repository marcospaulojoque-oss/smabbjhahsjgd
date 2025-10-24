# Makefile para Projeto Monjaro Docker

.PHONY: help build up down restart logs clean test health

# Variáveis
IMAGE_NAME = monjaro-app
CONTAINER_NAME = monjaro-app
COMPOSE_FILE = docker-compose.yml
PROD_COMPOSE_FILE = docker-compose.yml docker-compose.prod.yml

# Configuração
PORT ?= 8000
ENV_FILE ?= .env

help: ## Exibe esta ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build da imagem Docker
	docker build -t $(IMAGE_NAME):latest .

build-dev: ## Build para desenvolvimento
	docker-compose build

build-prod: ## Build para produção
	docker-compose -f $(PROD_COMPOSE_FILE) build

up: ## Inicia a aplicação em desenvolvimento
	docker-compose up -d
	@echo "✅ Aplicação iniciada em http://localhost:$(PORT)/"

up-prod: ## Inicia a aplicação em produção (com Nginx)
	docker-compose -f $(PROD_COMPOSE_FILE) --profile production up -d
	@echo "✅ Aplicação em produção iniciada em http://localhost/"

up-build: ## Build e sobe a aplicação
	make build && make up

down: ## Para todos os containers
	docker-compose down

down-prod: ## Para containers de produção
	docker-compose -f $(PROD_COMPOSE_FILE) down

restart: ## Reinicia a aplicação
	docker-compose restart

restart-prod: ## Reinicia em produção
	docker-compose -f $(PROD_COMPOSE_FILE) restart

logs: ## Exibe logs da aplicação
	docker-compose logs -f

logs-app: ## Logs apenas da aplicação
	docker-compose logs -f monjaro-app

logs-nginx: ## Logs apenas do Nginx
	docker-compose logs -f nginx

shell: ## Acessa shell do container
	docker-compose exec monjaro-app /bin/bash

shell-prod: ## Shell em produção
	docker-compose -f $(PROD_COMPOSE_FILE) exec monjaro-app /bin/bash

test: ## Executa testes da aplicação
	@echo "🧪 Testando aplicação..."
	curl -f http://localhost:$(PORT)/ || exit 1
	@echo "✅ Teste passou"

test-prod: ## Testa produção
	@echo "🧪 Testando produção..."
	curl -f http://localhost/ || exit 1
	@echo "✅ Teste de produção passou"

health: ## Verifica health dos containers
	docker-compose ps
	@echo ""
	@echo "🔍 Health Check:"
	@curl -s http://localhost:$(PORT)/health 2>/dev/null && echo "✅ App: Healthy" || echo "❌ App: Unhealthy"

clean: ## Limpa containers e imagens
	docker-compose down -v
	docker system prune -f
	docker volume prune -f
	@echo "🧹 Limpeza concluída"

clean-all: ## Limpa tudo incluindo imagens
	docker-compose down -v --rmi all
	docker system prune -a -f --volumes
	@echo "🧹 Limpeza completa concluída"

pull: ## Atualiza imagens
	docker-compose pull

status: ## Status dos containers
	docker-compose ps

stats: ## Estatísticas de uso
	docker stats

backup: ## Backup dos volumes
	@echo "💾 Realizando backup..."
	docker run --rm -v monjaro_monjaro-logs:/data -v $(pwd)/backups:/backup ubuntu tar cvf /backup/logs-$(shell date +%Y%m%d).tar /data
	@echo "✅ Backup concluído"

restore: ## Restaura backup (uso: make restore BACKUP=logs-20231224.tar)
	@if [ -z "$(BACKUP)" ]; then echo "❌ Especifique o arquivo: make restore BACKUP=logs-YYYYMMDD.tar"; exit 1; fi
	docker run --rm -v monjaro_monjaro-logs:/data -v $(pwd)/backups:/backup ubuntu tar xvf /backup/$(BACKUP) -C /
	@echo "✅ Restore concluído"

deploy-dev: ## Deploy para desenvolvimento
	@echo "🚀 Deploy para desenvolvimento..."
	git pull
	docker-compose build
	docker-compose up -d
	make test
	@echo "✅ Deploy dev concluído"

deploy-prod: ## Deploy para produção
	@echo "🚀 Deploy para produção..."
	git pull
	docker-compose -f $(PROD_COMPOSE_FILE) build
	docker-compose -f $(PROD_COMPOSE_FILE) --profile production up -d
	make test-prod
	@echo "✅ Deploy prod concluído"

install: ## Instala dependências e prepara ambiente
	@echo "📦 Preparando ambiente..."
	cp .env.example .env || true
	@echo "✅ Ambiente preparado"

dev: ## Ambiente completo de desenvolvimento
	make install
	make up-build
	make logs

prod: ## Ambiente completo de produção
	make install
	make up-prod
	make logs-prod