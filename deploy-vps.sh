#!/bin/bash
# Script de deploy para VPS Hostinger
# IP: 72.60.148.222
# User: root
# Port: 22

set -e

# Configurações
VPS_IP="72.60.148.222"
VPS_USER="root"
VPS_PASS="Govkaua123121#@"
VPS_PORT="22"
PROJECT_NAME="monjaro-app"
REMOTE_DIR="/opt/${PROJECT_NAME}"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo -e "${BLUE}"
echo " ██╗    ██╗██╗  ██╗ █████╗ ████████╗██╗ ██████╗██╗  ██╗███████╗████████╗"
echo " ██║    ██║██║  ██║██╔══██╗╚══██╔══╝██║██╔═══╝██║ ██╔╝██╔════╝╚══██╔══╝"
echo " ██║ █╗ ██║███████║███████║   ██║   ██║██║     █████╔╝ █████╗     ██║   "
echo " ██║███╗██║██╔══██║██╔══██║   ██║   ██║██║     ██╔═██╗ ██╔══╝     ██║   "
echo " ╚███╔███╔╝██║  ██║██║  ██║   ██║   ██║╚██████╗██║  ██╗███████╗   ██║   "
echo "  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   "
echo -e "${NC}"
echo -e "${BLUE}🚀 Deploy Monjaro App para VPS Hostinger${NC}"
echo -e "${BLUE}VPS: ${VPS_IP} | User: ${VPS_USER}${NC}"
echo "=========================================="
echo

# Função para executar comando na VPS
exec_ssh() {
    sshpass -p "${VPS_PASS}" ssh -o StrictHostKeyChecking=no -p ${VPS_PORT} ${VPS_USER}@${VPS_IP} "$1"
}

# Função para copiar arquivos para VPS
copy_to_vps() {
    sshpass -p "${VPS_PASS}" scp -o StrictHostKeyChecking=no -P ${VPS_PORT} -r "$1" ${VPS_USER}@${VPS_IP}:"$2"
}

# Verificar pré-requisitos locais
check_local() {
    log_info "Verificando pré-requisitos locais..."

    # Verificar sshpass
    if ! command -v sshpass >/dev/null 2>&1; then
        log_warn "Instalando sshpass..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y sshpass
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y sshpass
        elif command -v brew >/dev/null 2>&1; then
            brew install sshpass
        else
            log_error "Instale sshpass manualmente"
        fi
    fi

    # Verificar Docker local
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não está instalado localmente!"
        exit 1
    fi

    log_info "Pré-requisitos OK!"
}

# Preparar VPS
prepare_vps() {
    log_info "Preparando VPS..."

    # Criar diretório do projeto
    exec_ssh "mkdir -p ${REMOTE_DIR} && cd ${REMOTE_DIR}"

    # Instalar Docker na VPS
    log_info "Instalando Docker na VPS..."
    exec_ssh "
        command -v docker >/dev/null 2>&1 || {
            apt-get update
            apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            systemctl start docker
            systemctl enable docker
        }
    "

    # Instalar Docker Compose
    log_info "Instalando Docker Compose na VPS..."
    exec_ssh "
        command -v docker-compose >/dev/null 2>&1 || {
            curl -L 'https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-linux-x86_64' -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
        }
    "

    # Instalar outras ferramentas
    exec_ssh "apt-get install -y curl wget htop"

    log_info "VPS preparada!"
}

# Build da imagem local
build_image() {
    log_info "Build da imagem Docker local..."

    # Build da imagem
    docker build -t ${PROJECT_NAME}:latest .

    # Salvar imagem para enviar
    docker save ${PROJECT_NAME}:latest | gzip > ${PROJECT_NAME}.tar.gz

    log_info "Imagem buildada e salva!"
}

# Enviar arquivos para VPS
deploy_files() {
    log_info "Enviando arquivos para VPS..."

    # Criar diretório se não existir
    exec_ssh "mkdir -p ${REMOTE_DIR}"

    # Enviar imagem Docker
    copy_to_vps ${PROJECT_NAME}.tar.gz ${REMOTE_DIR}/

    # Enviar arquivos do projeto
    copy_to_vps docker-compose.yml ${REMOTE_DIR}/
    copy_to_vps docker-compose.prod.yml ${REMOTE_DIR}/
    copy_to_vps nginx/ ${REMOTE_DIR}/nginx/
    copy_to_vps .env.example ${REMOTE_DIR}/

    # Criar .env na VPS
    exec_ssh "
        cd ${REMOTE_DIR}
        if [ ! -f .env ]; then
            cp .env.example .env
            echo 'Arquivo .env criado'
        fi
    "

    log_info "Arquivos enviados!"
}

# Configurar na VPS
setup_vps() {
    log_info "Configurando aplicação na VPS..."

    exec_ssh "
        cd ${REMOTE_DIR}

        # Carregar imagem Docker
        docker load < ${PROJECT_NAME}.tar.gz

        # Parar containers antigos
        docker-compose down 2>/dev/null || true

        # Subir nova versão
        docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

        # Limpar imagem antiga
        rm -f ${PROJECT_NAME}.tar.gz
    "

    log_info "Configuração concluída!"
}

# Testar deploy
test_deploy() {
    log_info "Testando deploy..."

    # Esperar aplicação subir
    sleep 10

    # Testar se está respondendo
    if curl -f http://${VPS_IP}/ >/dev/null 2>&1; then
        log_info "✅ Aplicação está online!"
        log_info "URL: http://${VPS_IP}"
    else
        log_warn "⚠️  Aplicação pode não estar respondendo ainda"
        log_info "Verificando logs..."
        exec_ssh "cd ${REMOTE_DIR} && docker-compose logs --tail=20"
    fi

    # Verificar status dos containers
    exec_ssh "
        cd ${REMOTE_DIR}
        echo '=== Status dos Containers ==='
        docker-compose ps
        echo ''
        echo '=== Uso de Recursos ==='
        docker stats --no-stream
    "
}

# Configurar firewall
setup_firewall() {
    log_info "Configurando firewall..."

    exec_ssh "
        # Configurar UFW
        ufw --force reset
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 8000/tcp
        ufw --force enable

        echo 'Firewall configurado!'
    "
}

# Instalar SSL com Let's Encrypt
setup_ssl() {
    log_info "Instalando SSL com Let's Encrypt..."

    exec_ssh "
        cd ${REMOTE_DIR}

        # Instalar certbot
        apt-get install -y certbot python3-certbot-nginx

        # Gerar certificado (substitua seu-dominio.com)
        # certbot --nginx -d seu-dominio.com -d www.seu-dominio.com --non-interactive --agree-tos --email admin@seu-dominio.com

        echo 'Configure o domínio e execute manualmente:'
        echo 'certbot --nginx -d SEU_DOMINIO.COM'
    "

    log_warn "Configure seu domínio apontando para ${VPS_IP} e execute o comando certbot"
}

# Limpar
cleanup() {
    log_info "Limpando arquivos temporários..."
    rm -f ${PROJECT_NAME}.tar.gz
}

# Menu principal
main() {
    case "${1:-deploy}" in
        "prepare")
            check_local
            prepare_vps
            ;;
        "build")
            build_image
            ;;
        "deploy")
            check_local
            build_image
            deploy_files
            setup_vps
            test_deploy
            cleanup
            ;;
        "update")
            build_image
            deploy_files
            setup_vps
            test_deploy
            cleanup
            ;;
        "ssl")
            setup_ssl
            ;;
        "firewall")
            setup_firewall
            ;;
        "logs")
            exec_ssh "cd ${REMOTE_DIR} && docker-compose logs -f --tail=50"
            ;;
        "status")
            exec_ssh "cd ${REMOTE_DIR} && docker-compose ps && docker stats --no-stream"
            ;;
        "stop")
            exec_ssh "cd ${REMOTE_DIR} && docker-compose down"
            ;;
        "restart")
            exec_ssh "cd ${REMOTE_DIR} && docker-compose restart"
            ;;
        *)
            echo "Uso: $0 [prepare|build|deploy|update|ssl|firewall|logs|status|stop|restart]"
            echo
            echo "Comandos:"
            echo "  prepare - Prepara VPS com Docker"
            echo "  build   - Build da imagem local"
            echo "  deploy  - Deploy completo (recomendado primeiro uso)"
            echo "  update  - Atualização do deploy"
            echo "  ssl     - Instalar certificado SSL"
            echo "  firewall- Configurar firewall"
            echo "  logs    - Ver logs da VPS"
            echo "  status  - Ver status dos containers"
            echo "  stop    - Parar aplicação"
            echo "  restart - Reiniciar aplicação"
            echo
            echo "Exemplo de uso completo:"
            echo "  $0 prepare"
            echo "  $0 deploy"
            exit 1
            ;;
    esac

    echo
    log_info "Deploy concluído! 🎉"
    log_info "Acesse sua aplicação em: http://${VPS_IP}"
}

# Executar
main "$@"