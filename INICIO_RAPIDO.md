# 🚀 INÍCIO RÁPIDO

## ⚡ 3 PASSOS PARA RODAR O PROJETO

---

### 1️⃣ Abra o Terminal

No Linux, pressione **Ctrl+Alt+T**

---

### 2️⃣ Navegue até a pasta e inicie o servidor

Cole este comando:

```bash
cd "/home/blacklotus/Downloads/OFERTA MONJARO" && python3 proxy_api.py
```

Você verá:
```
🚀 Servidor iniciado em http://localhost:8000/
📡 Proxy de API de CPF ativo
🔒 CORS habilitado

Pressione Ctrl+C para parar
```

---

### 3️⃣ Abra no navegador

Cole na barra de endereço:
```
http://localhost:8000/
```

---

## ✅ PRONTO! Agora teste:

1. Clique em **"Verificar Elegibilidade"**
2. Insira CPF: **046.891.496-07**
3. Sistema valida automaticamente ✅

---

## ❓ PERGUNTAS FREQUENTES

### Por que não posso usar `python3 -m http.server`?

❌ Esse servidor **não resolve CORS**. Use `proxy_api.py`!

### Erro: "Address already in use"?

Outro processo está usando a porta 8000.

**Solução:**
```bash
# Parar outro servidor
lsof -i :8000
kill -9 <PID>

# Ou usar outra porta (edite proxy_api.py)
```

### Ainda vejo erro de CORS?

Certifique-se de:
- ✅ Estar usando `python3 proxy_api.py`
- ✅ Acessando via `http://localhost:8000/`
- ✅ NÃO abrindo arquivo diretamente (file://)

---

## 📚 DOCUMENTAÇÃO COMPLETA

- **SERVIDOR_PROXY.md** - Detalhes sobre o proxy e CORS
- **CONFIGURACAO_API.md** - Integração da API de CPF
- **COMO_USAR.md** - Guia completo de uso
- **NAVEGACAO_COMPLETA.md** - Mapa de navegação
- **WORKFLOW.md** - Fluxo detalhado do lead

---

## 🆘 PRECISA DE AJUDA?

1. Verifique se o servidor está rodando
2. Abra Console do navegador (F12) e veja erros
3. Leia SERVIDOR_PROXY.md para troubleshooting

---

**✅ Tudo configurado e funcionando!**
