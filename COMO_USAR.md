# 🚀 COMO USAR O PROJETO OFERTA MONJARO

## ⚠️ IMPORTANTE - LEIA PRIMEIRO

Este projeto **PRECISA** ser executado através de um **servidor web local**. 
Não funciona corretamente se você abrir os arquivos diretamente pelo navegador (file://).

---

## 🖥️ MÉTODO 1: SERVIDOR LOCAL (RECOMENDADO)

### Com Python 3 (Mais Fácil)

```bash
# 1. Abra o terminal
# 2. Navegue até a pasta do projeto
cd "/home/blacklotus/Downloads/OFERTA MONJARO"

# 3. Inicie o servidor
python3 -m http.server 8000

# 4. Abra no navegador
# http://localhost:8000/
```

Você verá algo como:
```
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
```

---

### Com Node.js

```bash
cd "/home/blacklotus/Downloads/OFERTA MONJARO"
npx http-server -p 8000
```

Depois abra: http://localhost:8000/

---

### Com PHP

```bash
cd "/home/blacklotus/Downloads/OFERTA MONJARO"
php -S localhost:8000
```

Depois abra: http://localhost:8000/

---

## 🌐 TESTANDO O FLUXO COMPLETO

### 1️⃣ Landing Page (index.html)
```
http://localhost:8000/
```
- Clique em "Verificar Elegibilidade"
- Modal de loading aparece (7 segundos)
- Redirect automático para cadastro

### 2️⃣ Cadastro
```
http://localhost:8000/cadastro/
```
- Insira um CPF válido
- Será redirecionado para validação

### 3️⃣ Validar Dados
```
http://localhost:8000/validar-dados/
```
- Validação automática
- Redirect para validação em andamento

### 4️⃣ Validação em Andamento
```
http://localhost:8000/validacao-em-andamento/
```
- Loading automático (3 segundos)
- Redirect para questionário

### 5️⃣ Questionário de Saúde
```
http://localhost:8000/questionario-saude/
```
- Responda as perguntas de saúde
- Submit para endereço

### 6️⃣ Endereço
```
http://localhost:8000/endereco/
```
- Preencha o endereço completo
- Submit para seleção

### 7️⃣ Seleção de Dosagem
```
http://localhost:8000/selecao/
```
- Escolha a dosagem do medicamento
- Confirme para solicitação

### 8️⃣ Solicitação
```
http://localhost:8000/solicitacao/
```
- Revise todos os dados
- Confirme para pagamento

### 9️⃣ Pagamento PIX
```
http://localhost:8000/pagamento_pix/
```
- Veja o QR Code PIX
- Aguarde confirmação

### 🔟 Obrigado
```
http://localhost:8000/obrigado/
```
- Confirmação do pedido
- Número do protocolo
- Próximos passos

---

## 🔧 RESOLUÇÃO DE PROBLEMAS

### Problema: "ERR_FILE_NOT_FOUND"

**Causa:** Você está tentando abrir o arquivo diretamente (file://)

**Solução:** Use um servidor local (veja acima)

---

### Problema: "Página fica carregando"

**Causa:** Modal de loading estava bloqueando

**Solução:** ✅ JÁ CORRIGIDO! O modal agora está oculto por padrão

---

### Problema: "Links não funcionam"

**Causa:** URLs absolutas não funcionam localmente

**Solução:** ✅ JÁ CORRIGIDO! Todos os 23 links foram convertidos para relativos

---

### Problema: "Modal não aparece ao clicar"

**Verificar:**
1. Você iniciou um servidor local?
2. Está acessando via http://localhost:8000/?
3. Abriu o console do navegador (F12) para ver erros?

---

## 📊 VERIFICAÇÃO DE FUNCIONAMENTO

### ✅ Checklist

- [ ] Servidor local iniciado?
- [ ] Acessando via http://localhost:8000/?
- [ ] Landing page carrega sem modal?
- [ ] Ao clicar em "Verificar Elegibilidade" o modal aparece?
- [ ] Modal redireciona para /cadastro após 7s?
- [ ] Formulário de cadastro funciona?

---

## 🆘 PRECISA DE AJUDA?

### Logs úteis

1. **Abra o Console do Navegador:** 
   - Pressione F12
   - Aba "Console"
   - Verifique erros em vermelho

2. **No Terminal (onde rodou o servidor):**
   - Veja as requisições GET
   - Verifique status codes (200 = OK, 404 = Não encontrado)

---

## 🎯 COMANDOS RÁPIDOS

```bash
# Iniciar servidor
cd "/home/blacklotus/Downloads/OFERTA MONJARO" && python3 -m http.server 8000

# Abrir no navegador (Linux)
xdg-open http://localhost:8000/

# Parar servidor
# Pressione Ctrl+C no terminal
```

---

## 📝 OBSERVAÇÕES

- O projeto usa `localStorage` para armazenar dados entre páginas
- Dados não são enviados para servidor (apenas local)
- Para limpar dados: Abra DevTools → Application → Local Storage → Clear

---

**✅ Projeto pronto para uso!**

Última atualização: 2024
