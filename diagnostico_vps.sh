#!/bin/bash

echo "🔍 DIAGNÓSTICO DO VPS - API Monjaro"
echo "=================================="
echo ""

# 1. Verificar se o Python está rodando
echo "1. Verificando se o proxy Python está rodando..."
if pgrep -f "python3 proxy_api.py" > /dev/null; then
    echo "✅ Python proxy está rodando (PID: $(pgrep -f 'python3 proxy_api.py'))"
else
    echo "❌ Python proxy NÃO está rodando!"
    echo "   Execute: cd /caminho/do/projeto && python3 proxy_api.py"
fi
echo ""

# 2. Verificar porta
echo "2. Verificando porta 8000..."
if netstat -tlnp | grep :8000 > /dev/null; then
    echo "✅ Porta 8000 está aberta"
    netstat -tlnp | grep :8000
else
    echo "❌ Porta 8000 NÃO está aberta!"
fi
echo ""

# 3. Testar DNS
echo "3. Testando resolução DNS..."
if nslookup apidecpf.site > /dev/null 2>&1; then
    echo "✅ DNS resolve apidecpf.site"
    nslookup apidecpf.site | grep -A1 "Name:"
else
    echo "❌ DNS NÃO resolve apidecpf.site!"
fi
echo ""

# 4. Testar conectividade com API externa
echo "4. Testando conectividade com API externa..."
if curl -s --max-time 10 "https://apidecpf.site/api-v1/consultas.php?cpf=04689149607&token=e3bd2312d93dca38d2003095196a09c2" > /dev/null; then
    echo "✅ Conexão com API externa funciona"
else
    echo "❌ Erro ao conectar com API externa!"
    echo "   Possíveis causas:"
    echo "   - Firewall bloqueando porta 443"
    echo "   - Proxy/rede corporativa"
    echo "   - Problemas de roteamento"
fi
echo ""

# 5. Testar API local
echo "5. Testando API local..."
if curl -s "http://localhost:8000/api/consultar-cpf?cpf=04689149607" > /dev/null; then
    echo "✅ API local responde"
    echo "   Resposta:"
    curl -s "http://localhost:8000/api/consultar-cpf?cpf=04689149607" | python3 -m json.tool | head -10
else
    echo "❌ API local NÃO responde!"
fi
echo ""

# 6. Verificar logs
echo "6. Verificando logs de erro (se existirem)..."
if [ -f "proxy_api.log" ]; then
    echo "📋 Logs recentes:"
    tail -20 proxy_api.log
else
    echo "ℹ️  Nenhum arquivo de log encontrado"
fi
echo ""

# 7. Verificar se está atrás de proxy reverso
echo "7. Verificando se está atrás de proxy reverso..."
if [ -f "/etc/nginx/sites-available/default" ] || [ -f "/etc/nginx/nginx.conf" ]; then
    echo "⚠️  Nginx detectado - Verifique a configuração:"
    echo "   - As rotas /api/* devem passar para Python:8000"
    echo "   - Ex: location /api/ { proxy_pass http://localhost:8000; }"
fi

if [ -f "/etc/apache2/sites-available/000-default.conf" ]; then
    echo "⚠️  Apache detectado - Verifique a configuração:"
    echo "   - ProxyPass /api/ http://localhost:8000/api/"
fi
echo ""

echo "🚀 SOLUÇÕES RECOMENDADAS:"
echo "========================"
echo ""
echo "Se o Python não estiver rodando:"
echo "  cd /caminho/do/projeto && nohup python3 proxy_api.py > proxy.log 2>&1 &"
echo ""
echo "Se houver firewall:"
echo "  sudo ufw allow 8000/tcp"
echo "  sudo ufw allow out 443/tcp"
echo ""
echo "Se estiver usando Nginx, adicione em /etc/nginx/sites-available/default:"
echo "  location /api/ {"
echo "      proxy_pass http://localhost:8000;"
echo "      proxy_set_header Host \$host;"
echo "      proxy_set_header X-Real-IP \$remote_addr;"
echo "  }"
echo ""
echo "Reinicie o serviço após mudanças:"
echo "  sudo systemctl restart nginx"