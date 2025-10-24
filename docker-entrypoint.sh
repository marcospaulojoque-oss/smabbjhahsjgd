#!/bin/bash
set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Banner
echo -e "${GREEN}"
echo "██╗      █████╗ ██╗██████╗ ██████╗ ███████╗██████╗ "
echo "██║     ██╔══██╗██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗"
echo "██║     ███████║██║██████╔╝██║  ███╗█████╗  ██████╔╝"
echo "██║     ██╔══██║██║██╔══██╗██║   ██║██╔══╝  ██╔══██╗"
echo "███████╗██║  ██║██║██║  ██║╚██████╔╝███████╗██║  ██║"
echo "╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "${YELLOW}Projeto Monjaro - Landing Page e Funil de Vendas${NC}"
echo -e "${YELLOW}Powered by Docker${NC}"
echo

# Função de log
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Verificar variáveis de ambiente
check_env() {
    log "Verificando variáveis de ambiente..."

    if [ "$KOREPAY_SECRET_KEY" = "YOUR_SECRET_KEY_HERE" ]; then
        warn "KOREPAY_SECRET_KEY não configurado (usando placeholder)"
    fi

    if [ "$KOREPAY_RANDOM_KEY" = "YOUR_RANDOM_KEY_HERE" ]; then
        warn "KOREPAY_RANDOM_KEY não configurado (usando placeholder)"
    fi

    # Exportar variáveis com valores padrão
    export PORT=${PORT:-8000}
    export KOREPAY_SECRET_KEY=${KOREPAY_SECRET_KEY:-YOUR_SECRET_KEY_HERE}
    export KOREPAY_RANDOM_KEY=${KOREPAY_RANDOM_KEY:-YOUR_RANDOM_KEY_HERE}
    export KOREPAY_SIMULATION_MODE=${KOREPAY_SIMULATION_MODE:-false}
    export CPF_API_TOKEN=${CPF_API_TOKEN:-e3bd2312d93dca38d2003095196a09c2}
}

# Verificar arquivos necessários
check_files() {
    log "Verificando arquivos da aplicação..."

    if [ ! -f "proxy_api.py" ]; then
        error "proxy_api.py não encontrado!"
    fi

    if [ ! -f "index.html" ]; then
        error "index.html não encontrado!"
    fi

    # Verificar permissões
    if [ ! -x "proxy_api.py" ]; then
        log "Ajustando permissões do proxy_api.py"
        chmod +x proxy_api.py
    fi
}

# Teste de conectividade
health_check() {
    log "Realizando health check..."

    # Esperar a aplicação iniciar
    sleep 2

    # Testar se a porta está respondendo
    if command -v curl >/dev/null 2>&1; then
        if curl -f -s http://localhost:${PORT}/ > /dev/null; then
            log "Aplicação está respondendo na porta ${PORT}"
        else
            warn "Aplicação pode não estar respondendo corretamente"
        fi
    else
        warn "curl não encontrado, pulando verificação HTTP"
    fi
}

# Configuração inicial
setup() {
    log "Configurando ambiente..."

    # Criar diretório de logs se não existir
    if [ ! -d "logs" ]; then
        mkdir -p logs
        log "Diretório de logs criado"
    fi

    # Configurar timezone
    export TZ=${TZ:-America/Sao_Paulo}

    # Log de configuração
    log "Configuração:"
    log "  - Porta: ${PORT}"
    log "  - Modo Simulação: ${KOREPAY_SIMULATION_MODE}"
    log "  - Timezone: ${TZ}"
    log "  - Python: $(python3 --version)"
    log "  - PID: $$"
}

# Handler de sinais
cleanup() {
    log "Recebido sinal para encerrar, realizando cleanup..."
    # Aqui pode adicionar tarefas de cleanup
    exit 0
}

# Registrar handlers
trap cleanup SIGTERM SIGINT

# Executar verificações
check_env
check_files
setup

# Iniciar aplicação
log "Iniciando aplicação Monjaro..."
log "Acesse: http://localhost:${PORT}/"
log "Pressione Ctrl+C para parar"

# Executar comando principal
if [ "$1" = "proxy_api.py" ]; then
    # Se for o comando padrão, executar com health check
    python3 proxy_api.py &
    APP_PID=$!

    # Health check em background
    health_check &

    # Esperar o processo principal
    wait $APP_PID
else
    # Executar comando customizado
    exec "$@"
fi