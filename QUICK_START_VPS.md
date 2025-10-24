# 🚀 Quick Start - Deploy na VPS Hostinger

## 📋 Pré-requisitos Locais

1. **Docker instalado** no seu computador
2. **Git** instalado
3. Acesso à internet

## ⚡ Deploy em 3 Comandos

### 1. Clonar o Projeto

```bash
git clone https://github.com/marcospaulojoque-oss/smabbjhahsjgd.git
cd smabbjhahsjgd
```

### 2. Executar Deploy Automático

```bash
chmod +x deploy-all.sh
./deploy-all.sh auto
```

### 3. Acessar a Aplicação

Abra no navegador: **http://72.60.148.222**

## 🔧 Se o Script Automático Falhar

### Opção A: Deploy Interativo

```bash
./deploy-all.sh
```

Escolha a opção 1 para deploy completo.

### Opção B: Deploy Manual Passo a Passo

```bash
# 1. Preparar VPS
./deploy-vps.sh prepare

# 2. Fazer deploy
./deploy-vps.sh deploy

# 3. Verificar status
./deploy-vps.sh status
```

## 📊 Comandos Úteis

```bash
# Ver logs em tempo real
./deploy-vps.sh logs

# Reiniciar aplicação
./deploy-vps.sh restart

# Parar aplicação
./deploy-vps.sh stop

# Ver status
./deploy-vps.sh status
```

## 🔒 Configurar SSL (HTTPS)

1. Aponte seu domínio para `72.60.148.222`
2. Execute:
   ```bash
   ./deploy-vps.sh ssl
   ```

## 📱 Acesso Rápido

| URL | Descrição |
|-----|-----------|
| http://72.60.148.222 | Aplicação principal |
| http://72.60.148.222/health | Health check |
| http://72.60.148.222/api/ | API endpoints |

## 🆘 Suporte

Se algo der errado:

1. **Verifique os logs:**
   ```bash
   ./deploy-vps.sh logs
   ```

2. **Verifique o status:**
   ```bash
   ./deploy-vps.sh status
   ```

3. **Acesse a VPS diretamente:**
   ```bash
   ssh root@72.60.148.222
   ```

4. **Verifique os containers:**
   ```bash
   ssh root@72.60.148.222 "docker ps"
   ```

## ✅ Checklist Pós-Deploy

- [ ] Aplicação acessível em http://72.60.148.222
- [ ] Health check funcionando
- [ ] CPF de teste funciona: 046.891.496-07
- [ ] Todas as 10 páginas carregam
- [ ] API responde corretamente
- [ ] Logs sem erros críticos

---

🎉 **Seu projeto Monjaro está no ar!**