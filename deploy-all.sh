#!/bin/bash
# Deploy completo para VPS Hostinger - Tudo Automático!
# IP: 72.60.148.222

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
CYAN='\033[0;36m'
NC='\033[0m'

# Banner animado
print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
 ██╗    ██╗██╗  ██╗ █████╗ ████████╗██╗ ██████╗██╗  ██╗███████╗████████╗
 ██║    ██║██║  ██║██╔══██╗╚══██╔══╝██║██╔═══╝██║ ██╔╝██╔════╝╚══██╔══╝
 ██║ █╗ ██║███████║███████║   ██║   ██║██║     █████╔╝ █████╗     ██║
 ██║███╗██║██╔══██║██╔══██║   ██║   ██║██║     ██╔═██╗ ██╔══╝     ██║
 ╚███╔███╔╝██║  ██║██║  ██║   ██║   ██║╚██████╗██║  ██╗███████╗   ██║
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝

 ██╗      ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗██╗███████╗██╗ ██████╗
 ██║     ██╔═══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██║██╔════╝██║██╔═══██╗
 ██║     ██║   ██║   ██║   ██║██║   ██║██╔██╗ ██║██║███████╗██║██║   ██║
 ██║     ██║   ██║   ██║   ██║██║   ██║██║╚██╗██║██║╚════██║██║██║   ██║
 ███████╗╚██████╔╝   ██║   ██║╚██████╔╝██║ ╚████║██║███████║██║╚██████╔╝
 ╚══════╝ ╚═════╝    ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚══════╝╚═╝ ╚═════╝
EOF
    echo -e "${NC}"
    echo -e "${BLUE}🏥 MONJARO - Deploy Automatizado para VPS${NC}"
    echo -e "${YELLOW}🌐 VPS: ${VPS_IP} | Porta: ${VPS_PORT}${NC}"
    echo "============================================================"
    echo
}

# Funções de log
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${BLUE}[STEP]${NC} $1"
    echo "----------------------------------------"
}

# Função para executar comando na VPS
exec_ssh() {
    sshpass -p "${VPS_PASS}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 -p ${VPS_PORT} ${VPS_USER}@${VPS_IP} "$1" 2>/dev/null || {
        log_error "Falha ao executar comando na VPS"
        return 1
    }
}

# Função para copiar arquivos
copy_to_vps() {
    sshpass -p "${VPS_PASS}" scp -o StrictHostKeyChecking=no -P ${VPS_PORT} -r "$1" ${VPS_USER}@${VPS_IP}:"$2" 2>/dev/null || {
        log_error "Falha ao copiar arquivos para VPS"
        return 1
    }
}

# Instalar dependências locais
install_local_deps() {
    log_step "Instalando dependências locais"

    # Verificar/Instalar sshpass
    if ! command -v sshpass >/dev/null 2>&1; then
        log_info "Instalando sshpass..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update -qq && sudo apt-get install -y sshpass
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y sshpass
        elif command -v brew >/dev/null 2>&1; then
            brew install hudochenkov/sshpass/sshpass
        else
            log_error "Não foi possível instalar sshpass automaticamente"
            exit 1
        fi
    fi

    # Verificar Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não está instalado! Instale em https://docs.docker.com/get-docker/"
        exit 1
    fi

    log_info "✅ Dependências locais OK!"
}

# Preparar VPS
prepare_vps() {
    log_step "Preparando VPS Hostinger"

    # Testar conexão
    log_info "Testando conexão com VPS..."
    if ! exec_ssh "echo 'Conexão OK!'"; then
        log_error "Não foi possível conectar à VPS!"
        log_info "Verifique:"
        echo "  - IP: ${VPS_IP}"
        echo "  - Usuário: ${VPS_USER}"
        echo "  - Senha: [CONFIGURADA]"
        echo "  - Porta: ${VPS_PORT}"
        exit 1
    fi

    # Instalar Docker na VPS
    log_info "Instalando Docker na VPS..."
    exec_ssh "
        command -v docker >/dev/null 2>&1 || {
            apt-get update -qq
            apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update -qq
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            systemctl start docker
            systemctl enable docker
            usermod -aG docker root
        }
    "

    # Instalar Docker Compose
    log_info "Instalando Docker Compose..."
    exec_ssh "
        command -v docker-compose >/dev/null 2>&1 || {
            curl -L 'https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-linux-x86_64' -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
        }
    "

    # Instalar utilitários
    log_info "Instalando utilitários..."
    exec_ssh "apt-get install -y curl wget unzip htop"

    # Criar diretório do projeto
    exec_ssh "mkdir -p ${REMOTE_DIR}"

    log_info "✅ VPS preparada!"
}

# Build da imagem
build_image() {
    log_step "Build da imagem Docker"

    # Verificar se estamos no diretório certo
    if [ ! -f "Dockerfile" ]; then
        log_error "Dockerfile não encontrado! Execute o script no diretório raiz do projeto."
        exit 1
    fi

    # Build
    log_info "Fazendo build da imagem ${PROJECT_NAME}..."
    docker build -t ${PROJECT_NAME}:latest . --progress=plain

    # Comprimir imagem
    log_info "Comprimindo imagem para envio..."
    docker save ${PROJECT_NAME}:latest | gzip > ${PROJECT_NAME}.tar.gz

    # Verificar tamanho
    SIZE=$(du -h ${PROJECT_NAME}.tar.gz | cut -f1)
    log_info "✅ Imagem criada (${SIZE})"
}

# Enviar arquivos
deploy_files() {
    log_step "Enviando arquivos para VPS"

    # Enviar imagem Docker
    log_info "Enviando imagem Docker..."
    copy_to_vps ${PROJECT_NAME}.tar.gz ${REMOTE_DIR}/

    # Enviar arquivos de configuração
    log_info "Enviando arquivos de configuração..."
    copy_to_vps docker-compose.yml ${REMOTE_DIR}/
    copy_to_vps docker-compose.prod.yml ${REMOTE_DIR}/
    copy_to_vps nginx/ ${REMOTE_DIR}/nginx/
    copy_to_vps .env.example ${REMOTE_DIR}/

    # Enviar script de inicialização
    cat > start-app.sh << 'EOF'
#!/bin/bash
cd /opt/monjaro-app

# Carregar imagem
docker load < monjaro-app.tar.gz

# Parar containers antigos
docker-compose down 2>/dev/null || true

# Iniciar nova versão
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Aguardar
sleep 5

# Verificar status
echo "=== Status dos Containers ==="
docker-compose ps

echo ""
echo "=== Acesse sua aplicação ==="
echo "URL: http://$(curl -s ifconfig.me)"
echo "Health: http://$(curl -s ifconfig.me)/health"
EOF

    copy_to_vps start-app.sh ${REMOTE_DIR}/
    exec_ssh "chmod +x ${REMOTE_DIR}/start-app.sh"

    log_info "✅ Arquivos enviados!"
}

# Configurar e iniciar
setup_and_start() {
    log_step "Configurando e iniciando aplicação"

    # Executar script na VPS
    exec_ssh "cd ${REMOTE_DIR} && ./start-app.sh"

    # Aguardar subir
    log_info "Aguardando aplicação iniciar..."
    sleep 10

    # Testar
    log_info "Testando aplicação..."
    if curl -f -s http://${VPS_IP}/ >/dev/null; then
        log_info "✅ Aplicação está ONLINE!"
        echo ""
        echo -e "${GREEN}🎉 DEPLOY REALIZADO COM SUCESSO! 🎉${NC}"
        echo ""
        echo -e "${CYAN}URL da Aplicação:${NC} http://${VPS_IP}"
        echo -e "${CYAN}Health Check:${NC} http://${VPS_IP}/health"
        echo ""
        echo -e "${YELLOW}Comandos úteis:${NC}"
        echo "  Ver logs: ./deploy-vps.sh logs"
        echo "  Ver status: ./deploy-vps.sh status"
        echo "  Parar: ./deploy-vps.sh stop"
        echo "  Reiniciar: ./deploy-vps.sh restart"
    else
        log_warn "⚠️  A aplicação pode estar demorando para subir"
        log_info "Verificando logs..."
        exec_ssh "cd ${REMOTE_DIR} && docker-compose logs --tail=20"
    fi
}

# Configurar firewall
setup_firewall() {
    log_step "Configurando firewall"

    exec_ssh "
        ufw --force reset
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 8000/tcp
        ufw --force enable
    "

    log_info "✅ Firewall configurado!"
}

# Limpar
cleanup() {
    log_step "Limpando arquivos temporários"
    rm -f ${PROJECT_NAME}.tar.gz start-app.sh
    log_info "✅ Limpeza concluída!"
}

# Menu interativo
show_menu() {
    echo -e "\n${YELLOW}Escolha uma opção:${NC}"
    echo "1) Deploy completo (recomendado)"
    echo "2) Apenas atualizar (já deployed antes)"
    echo "3) Ver status da VPS"
    echo "4) Ver logs"
    echo "5) Parar aplicação"
    echo "6) Reiniciar aplicação"
    echo "7) Configurar SSL"
    echo "0) Sair"
    echo
    read -p "Opção: " choice

    case $choice in
        1)
            install_local_deps
            prepare_vps
            build_image
            deploy_files
            setup_and_start
            setup_firewall
            cleanup
            ;;
        2)
            build_image
            deploy_files
            setup_and_start
            cleanup
            ;;
        3)
            exec_ssh "cd ${REMOTE_DIR} && docker-compose ps && docker stats --no-stream"
            ;;
        4)
            exec_ssh "cd ${REMOTE_DIR} && docker-compose logs -f --tail=50"
            ;;
        5)
            exec_ssh "cd ${REMOTE_DIR} && docker-compose down"
            ;;
        6)
            exec_ssh "cd ${REMOTE_DIR} && docker-compose restart"
            ;;
        7)
            echo -e "${YELLOW}Para configurar SSL:${NC}"
            echo "1. Aponte seu domínio para ${VPS_IP}"
            echo "2. Execute: ./deploy-vps.sh ssl"
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            log_error "Opção inválida!"
            show_menu
            ;;
    esac
}

# Main
main() {
    print_banner

    # Verificar modo
    if [ "$1" = "auto" ]; then
        log_info "Modo automático ativado"
        install_local_deps
        prepare_vps
        build_image
        deploy_files
        setup_and_start
        setup_firewall
        cleanup
    else
        show_menu
    fi
}

# Executar
main "$@"