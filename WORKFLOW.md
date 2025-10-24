# 🔄 WORKFLOW COMPLETO - OFERTA MONJARO

## 📋 FLUXO DE NAVEGAÇÃO ATUAL

### Etapa 1: Landing Page (index.html)
**Rota:** `/` ou `/index.html`
**Objetivo:** Apresentar o programa e captar interesse

**Navegação:**
- Botão "Verificar Elegibilidade" → `/cadastro`
- Botão "Entrar" no header → `/cadastro`

---

### Etapa 2: Cadastro (cadastro/index.html)
**Rota:** `/cadastro`
**Objetivo:** Capturar e validar CPF do lead

**Dados Coletados:**
- CPF

**Navegação:**
- Submit do formulário → `/validar-dados?cpf=${cpf}`

---

### Etapa 3: Validação de Dados (validar-dados/index.html)
**Rota:** `/validar-dados?cpf=XXX`
**Objetivo:** Validar dados do CPF em bases governamentais

**Processamento:**
- Validação de CPF
- Consulta de dados cadastrais
- Armazenamento em localStorage

**Navegação:**
- Automático após validação → `/validacao-em-andamento`

---

### Etapa 4: Validação em Andamento (validacao-em-andamento/index.html)
**Rota:** `/validacao-em-andamento`
**Objetivo:** Tela de loading/processamento

**Processamento:**
- Loading visual
- Preparação de dados

**Navegação:**
- Auto-redirect (timeout) → `/questionario-saude`

---

### Etapa 5: Questionário de Saúde (questionario-saude/index.html)
**Rota:** `/questionario-saude`
**Objetivo:** Avaliar elegibilidade médica do lead

**Dados Coletados:**
- Peso
- Altura
- Condições médicas
- Histórico de saúde

**Navegação:**
- Conclusão do questionário → `/endereco`

---

### Etapa 6: Endereço (endereco/index.html)
**Rota:** `/endereco`
**Objetivo:** Coletar endereço de entrega

**Dados Coletados:**
- CEP
- Rua
- Número
- Complemento
- Bairro
- Cidade
- Estado
- Telefone
- Email

**Navegação:**
- ⚠️ PRECISA SER CORRIGIDO → Deve ir para `/selecao`

---

### Etapa 7: Seleção de Dosagem (selecao/index.html)
**Rota:** `/selecao`
**Objetivo:** Escolher dosagem do medicamento

**Dados Coletados:**
- Dosagem selecionada (2.5mg, 5mg, 7.5mg, etc)

**Navegação:**
- Seleção confirmada → `/solicitacao`

---

### Etapa 8: Solicitação (solicitacao/index.html)
**Rota:** `/solicitacao`
**Objetivo:** Revisão final antes do pagamento

**Dados Exibidos:**
- Resumo de todos os dados coletados
- Medicamento selecionado
- Endereço de entrega
- Valor

**Navegação:**
- Confirmar → `/pagamento_pix`

---

### Etapa 9: Pagamento PIX (pagamento_pix/index.html)
**Rota:** `/pagamento_pix`
**Objetivo:** Finalizar com pagamento

**Funcionalidades:**
- Gerar QR Code PIX
- Código PIX copia e cola
- Countdown timer
- Verificação de pagamento

**Navegação:**
- Voltar → `/selecao`
- Pagamento confirmado → página de sucesso/obrigado

---

## 🔧 PROBLEMAS IDENTIFICADOS

### ❌ Problema 1: Falta redirect em endereco
**Arquivo:** `endereco/index.html`
**Problema:** Não tem redirect explícito para `/selecao` após submit do formulário
**Solução:** Adicionar `window.location.href = '/selecao'` após salvar dados

### ❌ Problema 2: Múltiplos redirects em pagamento_pix
**Arquivo:** `pagamento_pix/index.html`
**Problema:** Tem redirects para `redirectUrl` que não estão claros
**Solução:** Definir claramente o fluxo pós-pagamento

---

## ✅ FLUXO RECOMENDADO (CORRIGIDO)

```
┌─────────────────────┐
│  1. Landing Page    │ (Apresentação)
│  /index.html        │
└──────────┬──────────┘
           │ Click "Verificar Elegibilidade"
           ↓
┌─────────────────────┐
│  2. Cadastro        │ (Captura CPF)
│  /cadastro          │
└──────────┬──────────┘
           │ Submit CPF
           ↓
┌─────────────────────┐
│  3. Validar Dados   │ (Validação CPF)
│  /validar-dados     │
└──────────┬──────────┘
           │ Dados validados
           ↓
┌─────────────────────┐
│  4. Validação       │ (Loading)
│  /validacao-em-     │
│     andamento       │
└──────────┬──────────┘
           │ Auto-redirect
           ↓
┌─────────────────────┐
│  5. Questionário    │ (Elegibilidade)
│  /questionario-     │
│     saude           │
└──────────┬──────────┘
           │ Questionário completo
           ↓
┌─────────────────────┐
│  6. Endereço        │ (Coleta endereço)
│  /endereco          │
└──────────┬──────────┘
           │ Endereço salvo
           ↓
┌─────────────────────┐
│  7. Seleção         │ (Escolha dosagem)
│  /selecao           │
└──────────┬──────────┘
           │ Dosagem selecionada
           ↓
┌─────────────────────┐
│  8. Solicitação     │ (Revisão)
│  /solicitacao       │
└──────────┬──────────┘
           │ Confirmar
           ↓
┌─────────────────────┐
│  9. Pagamento PIX   │ (Finalização)
│  /pagamento_pix     │
└──────────┬──────────┘
           │ Pagamento confirmado
           ↓
┌─────────────────────┐
│  10. Obrigado       │ (Sucesso)
│  /obrigado          │ ⚠️ CRIAR
└─────────────────────┘
```

---

## 📝 DADOS ARMAZENADOS NO localStorage

| Chave | Conteúdo | Página que salva |
|-------|----------|------------------|
| `cpf` | CPF do lead | cadastro |
| `cpfData` | Dados completos do CPF | validar-dados |
| `nomeCompleto` | Nome completo | validar-dados |
| `questionnaireData` | Respostas do questionário | questionario-saude |
| `endereco_form_data` | Dados do endereço | endereco |
| `selected_dosage` | Dosagem selecionada | selecao |
| `protocoloValidacao` | Número do protocolo | validar-dados |

---

## 🔙 NAVEGAÇÃO REVERSA (VOLTAR)

Todas as páginas têm botão "Entrar" que redireciona para `/cadastro` quando não há usuário logado.

**Recomendação:** Implementar navegação reversa adequada:
- endereco → voltar para questionario-saude
- selecao → voltar para endereco
- solicitacao → voltar para selecao
- pagamento_pix → voltar para solicitacao (não para selecao)

---

## 🎯 PRÓXIMOS PASSOS

1. ✅ Corrigir redirect em `/endereco` para ir para `/selecao`
2. ✅ Limpar redirects em `/pagamento_pix`
3. ✅ Criar página `/obrigado` para sucesso do pagamento
4. ✅ Implementar navegação reversa consistente
5. ✅ Adicionar validação de dados antes de permitir prosseguir

---

**Última atualização:** $(date)
