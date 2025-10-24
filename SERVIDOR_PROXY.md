# 🚀 SERVIDOR COM PROXY PARA API DE CPF

## ✅ PROBLEMA RESOLVIDO: CORS

O erro de CORS foi resolvido com a criação de um **servidor proxy** que faz as requisições para a API externa e repassa os dados para o navegador.

---

## 🔧 COMO USAR

### Opção 1: Servidor com Proxy (RECOMENDADO)

Use este servidor para resolver problemas de CORS automaticamente:

```bash
cd "/home/blacklotus/Downloads/OFERTA MONJARO"
python3 proxy_api.py
```

Você verá:
```
🚀 Servidor iniciado em http://localhost:8000/
📡 Proxy de API de CPF ativo
🔒 CORS habilitado

Pressione Ctrl+C para parar
```

Depois abra no navegador:
```
http://localhost:8000/
```

---

### Opção 2: Servidor Simples (SEM proxy - CORS error)

⚠️ **NÃO USE ESTA OPÇÃO** - causará erro de CORS:

```bash
python3 -m http.server 8000
```

---

## 🔍 O QUE FOI CORRIGIDO

### 1. ✅ CORS Error
**Antes:**
```
Access to fetch at 'https://apidecpf.site/...' has been blocked by CORS policy
```

**Depois:**
- Requisições passam pelo proxy local
- Proxy adiciona headers CORS
- Navegador não bloqueia

### 2. ✅ API de CPF
**Antes:**
```javascript
const apiUrl = `https://apidecpf.site/api-v1/consultas.php?cpf=${cpf}&token=${token}`;
fetch(apiUrl); // ❌ CORS error
```

**Depois:**
```javascript
const apiUrl = `/api/consultar-cpf?cpf=${cpf}`;
fetch(apiUrl); // ✅ Passa pelo proxy local
```

### 3. ✅ APIs Mock
APIs que não existem agora retornam dados falsos válidos:

- `/api/farmacias-por-ip` → Mock com array vazio
- `/api/ip-geo` → Mock com localização padrão (São Paulo)

### 4. ✅ Consulta Detalhada Desabilitada
```javascript
// API secundária desabilitada pois não está disponível
consultaDetalhadaCpf() // Retorna imediatamente
```

### 5. ⚠️ Fontes 404 (Não crítico)
Os erros de fontes não impedem o funcionamento:
```
rawline-400.woff2:1  Failed to load resource: 404
fa-solid-900.woff2:1  Failed to load resource: 404
```

Isso só afeta a aparência. O sistema usa fontes fallback.

---

## 📊 COMO O PROXY FUNCIONA

```
┌─────────────┐
│  Navegador  │
└──────┬──────┘
       │ fetch('/api/consultar-cpf?cpf=123')
       ↓
┌──────────────────┐
│  Proxy Local     │ (proxy_api.py)
│  localhost:8000  │
└──────┬───────────┘
       │ Adiciona token
       │ Adiciona headers CORS
       ↓
┌────────────────────────┐
│  API Externa           │
│  apidecpf.site         │
└────────┬───────────────┘
         │ Retorna dados do CPF
         ↓
┌──────────────────┐
│  Proxy Local     │
│  localhost:8000  │
└──────┬───────────┘
       │ Adiciona CORS headers
       ↓
┌─────────────┐
│  Navegador  │ ✅ Recebe dados
└─────────────┘
```

---

## 🧪 TESTANDO

### Passo 1: Inicie o Servidor com Proxy

```bash
cd "/home/blacklotus/Downloads/OFERTA MONJARO"
python3 proxy_api.py
```

### Passo 2: Abra no Navegador

```
http://localhost:8000/
```

### Passo 3: Teste o Fluxo

1. Clique em "Verificar Elegibilidade"
2. Insira CPF: `046.891.496-07`
3. Aguarde validação
4. Verifique no Console (F12):

**Logs esperados:**
```
📊 DEBUG: Dados recebidos da API: {...}
📊 DEBUG: Dados adaptados: {...}
✓ Nome completo: Ana Paula Aparecida Ferreira
```

**SEM erros de CORS!** ✅

---

## 🔍 DEBUG

### Ver Requisições no Servidor

No terminal onde o proxy está rodando, você verá:

```
127.0.0.1 - - [16/Oct/2024 12:00:00] "GET /api/consultar-cpf?cpf=04689149607 HTTP/1.1" 200 -
127.0.0.1 - - [16/Oct/2024 12:00:01] "GET /api/farmacias-por-ip HTTP/1.1" 200 -
127.0.0.1 - - [16/Oct/2024 12:00:01] "GET /api/ip-geo HTTP/1.1" 200 -
```

### Ver Erros no Console do Navegador

Pressione **F12** → Aba **Console**

**Erros que AINDA aparecem (mas não são críticos):**

```
❌ rawline-400.woff2:1  Failed to load resource: 404
❌ fa-solid-900.woff2:1  Failed to load resource: 404
```

Esses erros são de fontes e não impedem o funcionamento!

**Erros que NÃO devem aparecer mais:**

```
✅ CORS policy (RESOLVIDO pelo proxy)
✅ Failed to fetch (RESOLVIDO pelo proxy)
```

---

## 📝 CÓDIGO DO PROXY

O arquivo `proxy_api.py` faz:

1. **Serve arquivos estáticos** (HTML, CSS, JS, imagens)
2. **Intercepta `/api/consultar-cpf`** e redireciona para API externa
3. **Adiciona headers CORS** em todas as respostas
4. **Mock de APIs** que não existem

### Estrutura:

```python
class CORSRequestHandler:
    def end_headers(self):
        # Adiciona CORS
        self.send_header('Access-Control-Allow-Origin', '*')
    
    def do_GET(self):
        if '/api/consultar-cpf' in self.path:
            # Faz proxy para API externa
            self.handle_cpf_api()
        elif '/api/farmacias-por-ip' in self.path:
            # Retorna mock
            self.handle_mock_farmacias()
        else:
            # Serve arquivo estático
            super().do_GET()
```

---

## ⚙️ CONFIGURAÇÕES DO PROXY

### Mudar Porta

Edite `proxy_api.py` linha final:

```python
if __name__ == '__main__':
    run(8000)  # Mude 8000 para outra porta
```

### Desabilitar Logs

No terminal, redirecione saída:

```bash
python3 proxy_api.py > /dev/null 2>&1
```

---

## 🔐 SEGURANÇA

⚠️ **IMPORTANTE:** Este proxy é apenas para desenvolvimento/testes!

**Para produção:**

1. Use um backend real (Node.js, Django, Flask)
2. Implemente autenticação
3. Adicione rate limiting
4. Valide entrada de dados
5. Use HTTPS

### Exemplo de Backend Seguro (Node.js):

```javascript
const express = require('express');
const app = express();

app.get('/api/consultar-cpf', async (req, res) => {
  // Validar CPF
  const cpf = req.query.cpf;
  if (!/^\d{11}$/.test(cpf)) {
    return res.status(400).json({ error: 'CPF inválido' });
  }
  
  // Rate limiting
  // Autenticação
  // Log
  
  // Fazer requisição para API
  const token = process.env.API_TOKEN;
  const response = await fetch(`https://apidecpf.site/...?cpf=${cpf}&token=${token}`);
  const data = await response.json();
  
  res.json(data);
});
```

---

## 🆘 PROBLEMAS COMUNS

### Problema: "Address already in use"

**Causa:** Porta 8000 já está em uso

**Solução 1:** Pare outro servidor na porta 8000

```bash
# Encontrar processo
lsof -i :8000

# Matar processo
kill -9 <PID>
```

**Solução 2:** Use outra porta

```bash
# Edite proxy_api.py e mude a porta
python3 proxy_api.py
```

---

### Problema: Ainda vejo erro de CORS

**Causa:** Você está usando `python3 -m http.server`

**Solução:** Use `python3 proxy_api.py`

---

### Problema: "ModuleNotFoundError"

**Causa:** Python 3 não instalado

**Solução:**

```bash
# Ubuntu/Debian
sudo apt install python3

# Verificar versão
python3 --version
```

---

## ✅ CHECKLIST

Antes de testar:

- [ ] Servidor proxy iniciado (`python3 proxy_api.py`)
- [ ] Acessando via `http://localhost:8000/`
- [ ] Console do navegador aberto (F12)
- [ ] Terminal do servidor visível para ver logs

Durante o teste:

- [ ] Landing page carrega sem modal
- [ ] Clique em "Verificar Elegibilidade"
- [ ] Modal aparece e redireciona
- [ ] Formulário de cadastro funciona
- [ ] CPF é validado SEM erro de CORS
- [ ] Dados aparecem corretamente

---

**✅ CORS resolvido! Projeto pronto para testes!**

Última atualização: 2024
