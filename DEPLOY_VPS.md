# Deploy no VPS - Guia Completo

## Problema: API retornando 404 no VPS

A API de CPF funciona localmente mas retorna 404 no VPS. Isso geralmente acontece por:

1. **Proxy reverso (Nginx/Apache) não configurado para passar rotas `/api/*`**
2. **Firewall bloqueando conexões externas**
3. **Python não rodando na porta correta**
4. **Permissões de usuário**

## Solução Rápida

### 1. Configurar o Proxy Reverso

#### Se usa NGINX:
```bash
sudo nano /etc/nginx/sites-available/default
```

Adicione dentro do bloco `server {`:
```nginx
# Rota principal para o site
location / {
    root /caminho/do/projeto;
    index index.html;
    try_files $uri $uri/ /index.html;
}

# Proxy para APIs Python
location /api/ {
    proxy_pass http://localhost:8000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

#### Se usa APACHE:
```bash
sudo nano /etc/apache2/sites-available/000-default.conf
```

Adicione:
```apache
<VirtualHost *:80>
    DocumentRoot /caminho/do/projeto

    # Proxy para API
    ProxyPass /api/ http://localhost:8000/api/
    ProxyPassReverse /api/ http://localhost:8000/api/

    # Configurações do site
    <Directory /caminho/do/projeto>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

### 2. Iniciar o Servidor Python

```bash
# Acessar diretório do projeto
cd /caminho/do/projeto

# Iniciar em background (persistente)
nohup python3 proxy_api.py > proxy_api.log 2>&1 &

# Verificar se está rodando
ps aux | grep proxy_api
```

### 3. Verificar Firewall

```bash
# Liberar portas
sudo ufw allow 8000/tcp  # Porta do Python
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS
sudo ufw allow out 443/tcp # Saída HTTPS (para API externa)

# Recarregar firewall
sudo ufw reload
```

### 4. Testar Tudo

```bash
# 1. Testar API localmente no VPS
curl "http://localhost:8000/api/consultar-cpf?cpf=04689149607"

# 2. Testar via domínio
curl "http://SEU_DOMINIO.com/api/consultar-cpf?cpf=04689149607"

# 3. Testar se o site responde
curl -I "http://SEU_DOMINIO.com/"
```

## Script Automático de Deploy

Crie o arquivo `deploy.sh`:
```bash
#!/bin/bash

echo "🚀 Deploy do Projeto Monjaro no VPS"
echo "=================================="

# Parar processos antigos
pkill -f "python3 proxy_api.py"

# Ir para o diretório
cd /var/www/monjaro  # MUDAR para seu diretório

# Baixar/atualizar arquivos (se usando git)
# git pull origin main

# Iniciar servidor Python
nohup python3 proxy_api.py > proxy_api.log 2>&1 &
echo "✅ Servidor Python iniciado"

# Esperar 2 segundos
sleep 2

# Testar API
if curl -s "http://localhost:8000/api/consultar-cpf?cpf=04689149607" > /dev/null; then
    echo "✅ API funcionando!"
else
    echo "❌ ERRO: API não responde!"
    echo "Verificando logs..."
    tail -20 proxy_api.log
fi

# Reiniciar Nginx se necessário
sudo systemctl reload nginx
echo "✅ Nginx recarregado"

echo ""
echo "🎉 Deploy concluído!"
echo "Acesse: http://SEU_DOMINIO.com"
```

## Diagnóstico de Problemas

Execute o script de diagnóstico:
```bash
chmod +x diagnostico_vps.sh
./diagnostico_vps.sh
```

## Logs Importantes

- **Python API**: `tail -f proxy_api.log`
- **Nginx**: `sudo tail -f /var/log/nginx/error.log`
- **Apache**: `sudo tail -f /var/log/apache2/error.log`

## Comandos Úteis

```bash
# Verificar processos rodando
ps aux | grep python

# Verificar portas abertas
netstat -tlnp | grep :8000

# Verificar conexões de rede
ss -tulpn

# Matar processo específico
kill -9 PID_DO_PROCESSO

# Reiniciar serviços
sudo systemctl restart nginx
sudo systemctl restart apache2
```

## Verificação Final

Teste o fluxo completo no navegador:
1. Acesse `http://SEU_DOMINIO.com`
2. Preencha CPF: `046.891.496-07`
3. Clique em continuar
4. Deve ir para página de validação com os dados corretos

## Problemas Comuns

### Erro 502 Bad Gateway
- Servidor Python não está rodando
- Porta 8000 bloqueada
- Configuração de proxy reverso incorreta

### Erro 404 na API
- Proxy reverso não configurado para `/api/`
- NGINX/Apache servindo arquivos estáticos diretamente

### Conexão com API externa falha
- Firewall bloqueando saída
- DNS não resolvendo
- Proxy corporativo bloqueando

## Suporte

Se ainda assim não funcionar, verifique:
1. O domínio está apontando para o IP correto do VPS?
2. O DNS propagou (pode levar até 24h)?
3. O certificado SSL está configurado (se usando HTTPS)?

Execute `./diagnostico_vps.sh` e envie o resultado para análise.