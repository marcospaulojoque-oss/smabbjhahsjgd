# Imagem base Python 3.11 slim
FROM python:3.11-slim

# Configurações de metadata
LABEL maintainer="marcospaulojoque-oss <noreply@github.com>"
LABEL description="Projeto Monjaro - Landing Page e Funil de Vendas"
LABEL version="1.0.0"

# Definir diretório de trabalho
WORKDIR /app

# Variáveis de ambiente
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    KOREPAY_SECRET_KEY=${KOREPAY_SECRET_KEY:-YOUR_SECRET_KEY_HERE} \
    KOREPAY_RANDOM_KEY=${KOREPAY_RANDOM_KEY:-YOUR_RANDOM_KEY_HERE} \
    KOREPAY_SIMULATION_MODE=${KOREPAY_SIMULATION_MODE:-false} \
    CPF_API_TOKEN=${CPF_API_TOKEN:-e3bd2312d93dca38d2003095196a09c2}

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements.txt (se existir)
# COPY requirements.txt .

# Instalar dependências Python (não há requirements.txt no projeto)
# RUN pip install --no-cache-dir -r requirements.txt

# Copiar arquivos da aplicação
COPY proxy_api.py .
COPY *.html .
COPY --chown=www-data:www-data cadastro/ ./cadastro/
COPY --chown=www-data:www-data validar-dados/ ./validar-dados/
COPY --chown=www-data:www-data validacao-em-andamento/ ./validacao-em-andamento/
COPY --chown=www-data:www-data questionario-saude/ ./questionario-saude/
COPY --chown=www-data:www-data endereco/ ./endereco/
COPY --chown=www-data:www-data selecao/ ./selecao/
COPY --chown=www-data:www-data solicitacao/ ./solicitacao/
COPY --chown=www-data:www-data pagamento_pix/ ./pagamento_pix/
COPY --chown=www-data:www-data obrigado/ ./obrigado/
COPY --chown=www-data:www-data static/ ./static/
COPY --chown=www-data:www-data index_files/ ./index_files/
COPY --chown=www-data:www-data fonts/ ./fonts/
COPY --chown=www-data:www-data webfonts/ ./webfonts/

# Criar usuário não-root para segurança
RUN groupadd -r appuser && useradd -r -g appuser appuser && \
    chown -R appuser:appuser /app
USER appuser

# Expor porta
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8000}/ || exit 1

# Comando de execução
CMD ["python3", "proxy_api.py"]