#!/bin/bash

# Script para fazer push do projeto para o GitHub
# Uso: ./push_script.sh SEU_USERNAME SEU_TOKEN

echo "🚀 Script de Push para GitHub"
echo "============================"

if [ $# -eq 0 ]; then
    echo "Uso: $0 <seu_username> <seu_token_github>"
    echo ""
    echo "Exemplo:"
    echo "  $0 marcospaulojoque-oss ghp_xxxxxxxxxxxxxxxxxxxx"
    echo ""
    echo "Para obter um token:"
    echo "  1. Vá para https://github.com/settings/tokens"
    echo "  2. Clique em 'Generate new token (classic)'"
    echo "  3. Selecione os scopes: repo"
    echo "  4. Copie o token gerado"
    exit 1
fi

USERNAME=$1
TOKEN=$2

# Verificar se o diretório é um repositório git
if [ ! -d ".git" ]; then
    echo "❌ Erro: Este diretório não é um repositório Git"
    exit 1
fi

# Verificar se há commits para fazer push
if git log --oneline -n 1 > /dev/null 2>&1; then
    echo "✅ Commit encontrado: $(git log --oneline -n 1)"
else
    echo "❌ Nenhum commit encontrado para fazer push"
    exit 1
fi

# Configurar URL com token
REMOTE_URL="https://${USERNAME}:${TOKEN}@github.com/marcospaulojoque-oss/smabbjhahsjgd.git"

echo "📤 Configurando remote com token..."
git remote set-url origin "${REMOTE_URL}"

echo "📤 Fazendo push para o repositório..."
git push -u origin master

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Sucesso! Projeto enviado para o GitHub"
    echo "🌐 Acesse: https://github.com/marcospaulojoque-oss/smabbjhahsjgd"
    echo ""
    echo "📊 Estatísticas:"
    echo "  - Commits: $(git rev-list --count HEAD)"
    echo "  - Arquivos: $(git ls-files | wc -l)"
    echo "  - Branch atual: $(git branch --show-current)"
else
    echo ""
    echo "❌ Erro ao fazer push"
    echo "Verifique:"
    echo "  - Se o token está correto"
    echo "  - Se você tem permissão para o repositório"
    echo "  - Se o repositório existe"
fi

# Limpar URL do remote (remover token)
echo "🔒 Limpando URL do remote..."
git remote set-url origin "https://github.com/marcospaulojoque-oss/smabbjhahsjgd.git"