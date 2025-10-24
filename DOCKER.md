# 🐳 Docker - Projeto Monjaro

Este documento descreve como executar o projeto Monjaro usando Docker e Docker Compose.

## 📋 Pré-requisitos

- Docker Engine 20.10+
- Docker Compose 2.0+
- 512MB de RAM mínimo
- 1GB de espaço em disco

## 🚀 Início Rápido

### 1. Clonar o repositório
```bash
git clone https://github.com/marcospaulojoque-oss/smabbjhahsjgd.git
cd smabbjhahsjgd
```

### 2. Configurar variáveis de ambiente (Opcional)
```bash
cp .env.example .env
# Editar .env com suas credenciais
```

### 3. Executar com Docker Compose
```bash
# Desenvolvimento
docker-compose up -d

# Produção
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 4. Acessar a aplicação
- **Sem Nginx:** http://localhost:8000
- **Com Nginx (produção):** http://localhost:80

## 📁 Estrutura Docker

```
.
├── Dockerfile                 # Imagem da aplicação
├── docker-compose.yml         # Configuração de desenvolvimento
├── docker-compose.prod.yml    # Configuração de produção
├── .dockerignore             # Arquivos ignorados no build
├── nginx/                    # Configurações do Nginx
│   ├── nginx.conf
│   └── conf.d/
│       └── default.conf
└── DOCKER.md                 # Este documento
```

## 🔧 Configuração

### Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|---------|
| `APP_PORT` | Porta da aplicação | `8000` |
| `NGINX_PORT` | Porta do Nginx | `80` |
| `NGINX_SSL_PORT` | Porta SSL do Nginx | `443` |
| `KOREPAY_SECRET_KEY` | Chave secreta KorePay | `YOUR_SECRET_KEY_HERE` |
| `KOREPAY_RANDOM_KEY` | Chave aleatória KorePay | `YOUR_RANDOM_KEY_HERE` |
| `KOREPAY_SIMULATION_MODE` | Modo simulação | `false` |
| `CPF_API_TOKEN` | Token API CPF | `e3bd2312d93dca38d2003095196a09c2` |

### Build Customizado

```bash
# Build da imagem
docker build -t monjaro-app:latest .

# Build com argumentos
docker build \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  -t monjaro-app:latest .
```

## 📊 Comandos Úteis

### Gerenciamento de Containers
```bash
# Ver containers em execução
docker-compose ps

# Ver logs
docker-compose logs -f monjaro-app

# Reiniciar aplicação
docker-compose restart monjaro-app

# Parar todos os serviços
docker-compose down

# Remover volumes (cuidado!)
docker-compose down -v
```

### Debug
```bash
# Executar comando no container
docker-compose exec monjaro-app python3 --version

# Acessar shell do container
docker-compose exec monjaro-app /bin/bash

# Ver health check
docker inspect monjaro-app | grep Health -A 10
```

### Monitoramento
```bash
# Ver uso de recursos
docker stats

# Ver eventos do Docker
docker events --filter container=monjaro-app
```

## 🏭 Produção

### 1. Configurar Produção
```bash
# Criar .env.production
cp .env.example .env.production
# Configurar variáveis de produção
```

### 2. Executar em Produção
```bash
# Com Nginx reverse proxy
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile production up -d
```

### 3. SSL/TLS (HTTPS)
1. Coloque os certificados em `nginx/ssl/`
2. Descomente a configuração HTTPS em `nginx/conf.d/default.conf`
3. Reinicie os containers

### 4. Backup
```bash
# Backup dos volumes
docker run --rm -v monjaro_monjaro-logs:/data -v $(pwd):/backup ubuntu tar cvf /backup/logs-backup.tar /data
```

## 🔒 Segurança

- ✅ Roda com usuário não-root
- ✅ Variáveis de ambiente configuráveis
- ✅ Headers de segurança no Nginx
- ✅ Health checks ativos
- ✅ Limites de recursos configuráveis

## 🐛 Troubleshooting

### Problemas Comuns

1. **Porta já em uso**
   ```bash
   # Verificar processo na porta
   sudo lsof -i :8000

   # Mudar porta no docker-compose.yml
   ports:
     - "8080:8000"  # Usar 8080 ao invés de 8000
   ```

2. **Permissões negadas**
   ```bash
   # Verificar permissões
   ls -la proxy_api.py

   # Corrigir permissões
   chmod +x proxy_api.py
   ```

3. **Container não inicia**
   ```bash
   # Ver logs detalhados
   docker-compose logs --tail=50 monjaro-app

   # Verificar imagem
   docker images | grep monjaro
   ```

4. **Health check falhando**
   ```bash
   # Verificar se aplicação responde
   curl http://localhost:8000/

   # Desabilitar health check temporariamente
   # Comentar a linha HEALTHCHECK no Dockerfile
   ```

### Limpeza
```bash
# Remover imagens órfãs
docker image prune -f

# Remover tudo (cuidado!)
docker system prune -a -f
```

## 📈 Performance

### Otimizações Aplicadas
- Imagem Python slim para menor tamanho
- Multi-stage build não necessário (puro Python)
- Cache de assets estáticos no Nginx
- Compressão gzip habilitada
- Keep-alive connections

### Benchmarks
- **Build time:** ~30 segundos
- **Image size:** ~150MB
- **Startup time:** ~5 segundos
- **Memory usage:** ~50-100MB

## 🔄 CI/CD

### GitHub Actions (Exemplo)
```yaml
name: Docker CI/CD

on:
  push:
    branches: [main]

jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build Docker image
        run: docker build -t monjaro-app:${{ github.sha }} .

      - name: Run tests
        run: |
          docker run --rm -d -p 8000:8000 monjaro-app:${{ github.sha }}
          curl -f http://localhost:8000/
```

## 📞 Suporte

Para problemas com Docker:
1. Verifique os logs: `docker-compose logs`
2. Consulte o troubleshooting acima
3. Abra uma issue no repositório

---

🐳 **Docker torna o deployment do Monjaro fácil e reproduzível!**