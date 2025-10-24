#!/bin/bash
# Script completo de build e deploy do Projeto Monjaro
# Uso: ./build.sh [dev|prod|cloud]

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configurações
PROJECT_NAME="monjaro-app"
VERSION=${VERSION:-latest}
REGISTRY=${REGISTRY:-}
ENVIRONMENT=${1:-dev}

# Banner
echo -e "${CYAN}"
echo " ██╗    ██╗██╗  ██╗ █████╗ ████████╗██╗ ██████╗██╗  ██╗███████╗████████╗"
echo " ██║    ██║██║  ██║██╔══██╗╚══██╔══╝██║██╔═══╝██║ ██╔╝██╔════╝╚══██╔══╝"
echo " ██║ █╗ ██║███████║███████║   ██║   ██║██║     █████╔╝ █████╗     ██║   "
echo " ██║███╗██║██╔══██║██╔══██║   ██║   ██║██║     ██╔═██╗ ██╔══╝     ██║   "
echo " ╚███╔███╔╝██║  ██║██║  ██║   ██║   ██║╚██████╗██║  ██╗███████╗   ██║   "
echo "  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   "
echo -e "${NC}"
echo -e "${BLUE}🏥 Projeto Monjaro - Build & Deploy Automatizado${NC}"
echo -e "${BLUE}API Python + Landing Page + Funil de Vendas${NC}"
echo "========================================================="
echo

# Funções
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."

    # Verificar Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não está instalado!"
        echo "Instale Docker em: https://docs.docker.com/get-docker/"
    fi

    # Verificar Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "Docker Compose não está instalado!"
        echo "Instale Docker Compose em: https://docs.docker.com/compose/install/"
    fi

    log_info "Pré-requisitos OK!"
}

# Limpar builds anteriores
clean() {
    log_info "Limpando builds anteriores..."

    # Parar containers
    docker-compose down 2>/dev/null || true
    docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

    # Remover imagens antigas
    docker rmi ${PROJECT_NAME}:${VERSION} 2>/dev/null || true
    docker rmi ${PROJECT_NAME}:latest 2>/dev/null || true

    # Limpar dangling images
    docker image prune -f

    log_info "Limpeza concluída!"
}

# Build da imagem
build_image() {
    log_info "Build da imagem Docker..."

    # Build com build-args para metadata
    docker build \
        --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
        --build-arg VERSION=${VERSION} \
        --build-arg VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown") \
        -t ${PROJECT_NAME}:${VERSION} \
        -t ${PROJECT_NAME}:latest \
        .

    log_info "Build concluído!"
}

# Testar imagem
test_image() {
    log_info "Testando imagem..."

    # Iniciar container em modo teste
    docker run --rm -d \
        --name ${PROJECT_NAME}-test \
        -p 8001:8000 \
        -e PORT=8000 \
        -e KOREPAY_SIMULATION_MODE=true \
        ${PROJECT_NAME}:${VERSION}

    # Esperar iniciar
    sleep 5

    # Testar health check
    if curl -f http://localhost:8001/ >/dev/null 2>&1; then
        log_info "✅ Teste passed!"
    else
        log_error "❌ Teste failed!"
    fi

    # Parar container de teste
    docker stop ${PROJECT_NAME}-test 2>/dev/null || true

    log_info "Teste concluído!"
}

# Deploy desenvolvimento
deploy_dev() {
    log_info "Deploy em ambiente de desenvolvimento..."

    # Copiar .env.example se não existir
    if [ ! -f .env ]; then
        cp .env.example .env
        log_warn ".env criado a partir de .env.example"
    fi

    # Subir com docker-compose
    docker-compose up -d

    # Esperar subir
    sleep 3

    # Verificar status
    if docker-compose ps | grep -q "Up"; then
        log_info "✅ Deploy dev concluído!"
        log_info "Acesse: http://localhost:8000"
        docker-compose ps
    else
        log_error "❌ Deploy dev falhou!"
        docker-compose logs
    fi
}

# Deploy produção
deploy_prod() {
    log_info "Deploy em ambiente de produção..."

    # Verificar .env
    if [ ! -f .env ]; then
        log_error ".env não encontrado! Configure as variáveis de produção."
    fi

    # Verificar variáveis críticas
    if grep -q "YOUR_SECRET_KEY_HERE" .env; then
        log_warn "⚠️  Configure as credenciais reais no .env!"
    fi

    # Subir produção com Nginx
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile production up -d

    # Esperar subir
    sleep 5

    # Verificar status
    if docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps | grep -q "Up"; then
        log_info "✅ Deploy produção concluído!"
        log_info "Acesse: http://localhost"
        docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps
    else
        log_error "❌ Deploy produção falhou!"
        docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs
    fi
}

# Deploy para nuvem
deploy_cloud() {
    log_info "Preparando deploy para nuvem..."

    # Build para cloud
    docker build \
        --target production \
        --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
        --build-arg VERSION=${VERSION} \
        -t ${PROJECT_NAME}:${VERSION} \
        .

    # Tag para registry
    if [ -n "$REGISTRY" ]; then
        docker tag ${PROJECT_NAME}:${VERSION} ${REGISTRY}/${PROJECT_NAME}:${VERSION}
        docker tag ${PROJECT_NAME}:latest ${REGISTRY}/${PROJECT_NAME}:latest

        log_info "Imagem tagada para ${REGISTRY}"
        log_info "Para enviar: docker push ${REGISTRY}/${PROJECT_NAME}:${VERSION}"
    fi

    log_info "Deploy cloud preparado!"

    # Gerar scripts de deploy
    cat > deploy-cloud.sh << EOF
#!/bin/bash
# Deploy script for ${PROJECT_NAME}:${VERSION}

# Pull latest image
docker pull ${REGISTRY}${PROJECT_NAME}:${VERSION}

# Run container
docker run -d \\
    --name ${PROJECT_NAME} \\
    --restart unless-stopped \\
    -p 80:8000 \\
    -e PORT=8000 \\
    -e KOREPAY_SECRET_KEY=\$KOREPAY_SECRET_KEY \\
    -e KOREPAY_RANDOM_KEY=\$KOREPAY_RANDOM_KEY \\
    -e KOREPAY_SIMULATION_MODE=false \\
    -e CPF_API_TOKEN=\$CPF_API_TOKEN \\
    ${REGISTRY}${PROJECT_NAME}:${VERSION}

echo "Deploy concluído!"
EOF

    chmod +x deploy-cloud.sh
    log_info "Script deploy-cloud.sh gerado!"
}

# Gerar relatório
generate_report() {
    log_info "Gerando relatório de deployment..."

    cat > deployment-report.md << EOF
# Deployment Report - Monjaro App

## Informações
- **Data:** $(date)
- **Ambiente:** ${ENVIRONMENT}
- **Versão:** ${VERSION}
- **Hash:** $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

## Imagem Docker
- **Nome:** ${PROJECT_NAME}
- **Tag:** ${VERSION}
- **Size:** $(docker images ${PROJECT_NAME}:${VERSION} --format "table {{.Size}}" | tail -n 1)
- **ID:** $(docker images ${PROJECT_NAME}:${VERSION} --format "table {{.ID}}" | tail -n 1)

## Containers
$(docker-compose ps 2>/dev/null || docker ps --filter "name=${PROJECT_NAME}")

## URLs
- **Aplicação:** http://localhost:${PORT:-8000}
- **Health Check:** http://localhost:${PORT:-8000}/health

## Logs
Ver logs com: docker-compose logs -f

## Cleanup
Parar com: docker-compose down
Limpar com: docker system prune -f
EOF

    log_info "Relatório gerado: deployment-report.md"
}

# Menu principal
main() {
    echo "Ambiente selecionado: ${ENVIRONMENT}"
    echo

    case $ENVIRONMENT in
        "dev")
            check_prerequisites
            clean
            build_image
            test_image
            deploy_dev
            generate_report
            ;;
        "prod")
            check_prerequisites
            clean
            build_image
            test_image
            deploy_prod
            generate_report
            ;;
        "cloud")
            check_prerequisites
            clean
            build_image
            test_image
            deploy_cloud
            generate_report
            ;;
        "test")
            check_prerequisites
            build_image
            test_image
            ;;
        "clean")
            clean
            ;;
        *)
            echo "Uso: $0 [dev|prod|cloud|test|clean]"
            echo
            echo "Ambientes:"
            echo "  dev   - Desenvolvimento (porta 8000)"
            echo "  prod  - Produção com Nginx (porta 80)"
            echo "  cloud - Prepara imagem para nuvem"
            echo "  test  - Apenas build e teste"
            echo "  clean - Limpa containers e imagens"
            echo
            echo "Variáveis:"
            echo "  VERSION=v1.0.0  - Versão da imagem"
            echo "  REGISTRY=registry.com/ - Registry remoto"
            exit 1
            ;;
    esac

    echo
    log_info "Processo concluído com sucesso! 🎉"
}

# Executar
main "$@"