# 🚀 Deploy na VPS Hostinger

Guia completo para fazer deploy do projeto Monjaro na VPS Hostinger.

## 📋 Informações da VPS

- **IP:** `72.60.148.222`
- **Usuário:** `root`
- **Porta SSH:** `22`
- **SO:** Ubuntu 20.04/22.04
- **Provider:** Hostinger

## 🎯 Deploy Automatizado (Recomendado)

### Opção 1: Script Completo (Tudo-em-Um)

Execute o script automatizado que faz tudo:

```bash
# Clonar o repositório
git clone https://github.com/marcospaulojoque-oss/smabbjhahsjgd.git
cd smabbjhahsjgd

# Executar deploy automático (interativo)
./deploy-all.sh

# Ou executar em modo automático (sem interação)
./deploy-all.sh auto
```

### Opção 2: Passo a Passo

1. **Preparar VPS**
   ```bash
   ./deploy-vps.sh prepare
   ```

2. **Deploy Completo**
   ```bash
   ./deploy-vps.sh deploy
   ```

## 📁 Scripts de Deploy

| Script | Descrição |
|--------|-----------|
| `deploy-all.sh` | Deploy completo automatizado |
| `deploy-vps.sh` | Deploy manual com opções |
| `build.sh` | Build local de imagens Docker |

## 🛠️ Comandos Úteis

### Gerenciamento da Aplicação

```bash
# Ver status
./deploy-vps.sh status

# Ver logs em tempo real
./deploy-vps.sh logs

# Reiniciar aplicação
./deploy-vps.sh restart

# Parar aplicação
./deploy-vps.sh stop

# Atualizar (fazer novo deploy)
./deploy-vps.sh update
```

### Manutenção da VPS

```bash
# Configurar firewall
./deploy-vps.sh firewall

# Instalar SSL (Let's Encrypt)
./deploy-vps.sh ssl

# Acessar VPS via SSH
ssh root@72.60.148.222

# Ver containers na VPS
ssh root@72.60.148.222 "cd /opt/monjaro-app && docker-compose ps"
```

## 🌐 Acessando a Aplicação

Após o deploy, acesse:

- **URL Principal:** http://72.60.148.222
- **Health Check:** http://72.60.148.222/health
- **API:** http://72.60.148.222/api/

## 🔧 Estrutura na VPS

```
/opt/monjaro-app/
├── docker-compose.yml
├── docker-compose.prod.yml
├── .env
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       └── default.conf
├── logs/
└── Docker containers
```

## 🔒 Configuração SSL (HTTPS)

### Automático com Let's Encrypt

1. **Configurar Domínio**
   - Aponte seu domínio para `72.60.148.222`
   - Aguarde a propagação DNS

2. **Instalar Certificado**
   ```bash
   ./deploy-vps.sh ssl
   ```

## 📊 Monitoramento

### Ver Recursos

```bash
# CPU e Memória
ssh root@72.60.148.222 "docker stats"

# Disco
ssh root@72.60.148.222 "df -h"
```

## 🔧 Troubleshooting

### Problemas Comuns

1. **Aplicação não sobe**
   ```bash
   # Ver logs
   ./deploy-vps.sh logs
   # Ver status
   ./deploy-vps.sh status
   # Reiniciar
   ./deploy-vps.sh restart
   ```

2. **Erro de conexão SSH**
   ```bash
   # Verificar se VPS está online
   ping 72.60.148.222
   ```

## ✅ Checklist de Deploy

- [ ] Clonar repositório
- [ ] Executar `./deploy-all.sh`
- [ ] Configurar variáveis de ambiente
- [ ] Testar aplicação no navegador
- [ ] Configurar domínio (opcional)
- [ ] Instalar SSL (opcional)

---

🎉 **Parabéns! Seu projeto Monjaro está no ar na VPS!**
