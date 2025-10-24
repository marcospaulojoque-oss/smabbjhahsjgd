#!/bin/bash
# Script para testar a configuração Docker

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🐳 Teste de Configuração Docker - Projeto Monjaro${NC}"
echo "================================================"
echo

# Verificar Docker
check_docker() {
    echo -n "Verificando Docker... "
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $(docker --version)"
        DOCKER_INSTALLED=true
    else
        echo -e "${RED}✗${NC} Docker não encontrado"
        DOCKER_INSTALLED=false
    fi
}

# Verificar Docker Compose
check_docker_compose() {
    echo -n "Verificando Docker Compose... "
    if command -v docker-compose >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $(docker-compose --version)"
        COMPOSE_INSTALLED=true
    else
        echo -e "${RED}✗${NC} Docker Compose não encontrado"
        COMPOSE_INSTALLED=false
    fi
}

# Verificar arquivos Docker
check_files() {
    echo -e "\n${YELLOW}Verificando arquivos Docker:${NC}"

    files=(
        "Dockerfile"
        "docker-compose.yml"
        "docker-compose.prod.yml"
        ".dockerignore"
        "docker-entrypoint.sh"
        "DOCKER.md"
        "Makefile"
    )

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "  ${GREEN}✓${NC} $file"
        else
            echo -e "  ${RED}✗${NC} $file (ausente)"
        fi
    done
}

# Verificar estrutura de diretórios
check_structure() {
    echo -e "\n${YELLOW}Verificando estrutura:${NC}"

    dirs=(
        "nginx/conf.d"
        "cadastro"
        "validar-dados"
        "questionario-saude"
        "endereco"
        "selecao"
        "solicitacao"
        "pagamento_pix"
        "obrigado"
        "static"
    )

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "  ${GREEN}✓${NC} $dir/"
        else
            echo -e "  ${RED}✗${NC} $dir/ (ausente)"
        fi
    done
}

# Simular build
simulate_build() {
    echo -e "\n${YELLOW}Simulando build Docker:${NC}"

    if [ "$DOCKER_INSTALLED" = true ]; then
        echo "Comando que seria executado:"
        echo "  docker build -t monjaro-app:latest ."
        echo
        echo "Para testar o build:"
        echo "  make build"
        echo "  docker-compose build"
    else
        echo -e "${RED}Docker não está instalado${NC}"
        echo
        echo "Para instalar Docker:"
        echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
        echo "  sudo sh get-docker.sh"
        echo
        echo "Para instalar Docker Compose:"
        echo "  sudo curl -L \"https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
        echo "  sudo chmod +x /usr/local/bin/docker-compose"
    fi
}

# Comandos para execução
show_commands() {
    echo -e "\n${YELLOW}Comandos para execução:${NC}"
    echo
    echo "Desenvolvimento:"
    echo "  docker-compose up -d"
    echo "  make up"
    echo "  make dev"
    echo
    echo "Produção:"
    echo "  docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d"
    echo "  make up-prod"
    echo "  make prod"
    echo
    echo "Build:"
    echo "  docker build -t monjaro-app:latest ."
    echo "  make build"
    echo
    echo "Logs:"
    echo "  docker-compose logs -f"
    echo "  make logs"
    echo
    echo "Parar:"
    echo "  docker-compose down"
    echo "  make down"
}

# Verificar variáveis de ambiente
check_env() {
    echo -e "\n${YELLOW}Variáveis de ambiente:${NC}"

    env_vars=(
        "PORT=8000"
        "KOREPAY_SECRET_KEY"
        "KOREPAY_RANDOM_KEY"
        "KOREPAY_SIMULATION_MODE=false"
        "CPF_API_TOKEN"
    )

    for var in "${env_vars[@]}"; do
        echo "  $var"
    done

    if [ ! -f ".env" ]; then
        echo -e "\n${YELLOW}Dica: Copie .env.example para .env${NC}"
        echo "  cp .env.example .env"
    fi
}

# Executar verificações
main() {
    check_docker
    check_docker_compose
    check_files
    check_structure
    check_env
    simulate_build
    show_commands

    echo -e "\n${GREEN}✅ Teste de configuração concluído!${NC}"
    echo -e "\nPara mais informações, veja ${YELLOW}DOCKER.md${NC}"
}

main "$@"