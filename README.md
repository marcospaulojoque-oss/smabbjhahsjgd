# 🏥 OFERTA MONJARO - Projeto Completo

Projeto de landing page e funil de vendas para o programa de distribuição do medicamento Monjaro (tirzepatida).

---

## 📋 ÍNDICE

- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Fluxo do Lead](#-fluxo-do-lead)
- [Navegação](#-navegação)
- [Documentação](#-documentação)
- [Características](#-características)
- [Como Usar](#-como-usar)

---

## 📁 ESTRUTURA DO PROJETO

```
OFERTA MONJARO/
├── index.html                          # Landing page principal
├── cadastro/                           # Captura de CPF
├── validar-dados/                      # Validação de dados governamentais
├── validacao-em-andamento/             # Tela de loading
├── questionario-saude/                 # Questionário de elegibilidade
├── endereco/                           # Coleta de endereço
├── selecao/                            # Seleção de dosagem
├── solicitacao/                        # Revisão final
├── pagamento_pix/                      # Pagamento via PIX
├── obrigado/                           # Confirmação de pedido ✨
│
├── WORKFLOW.md                         # Fluxo detalhado
├── NAVEGACAO_COMPLETA.md               # Mapa de navegação
├── RELATORIO_LIMPEZA.md                # Relatório de tracking
└── README.md                           # Este arquivo
```

---

## 🚀 FLUXO DO LEAD

```
┌─────────────┐
│   LANDING   │ ← Usuário descobre a oferta
│  INDEX.HTML │
└──────┬──────┘
       │ Click "Verificar Elegibilidade"
       ↓
┌─────────────┐
│  CADASTRO   │ ← Insere CPF
│     CPF     │
└──────┬──────┘
       │ Submit
       ↓
┌─────────────┐
│  VALIDAR    │ ← Consulta dados governamentais
│   DADOS     │
└──────┬──────┘
       │ Auto-redirect
       ↓
┌─────────────┐
│ VALIDAÇÃO   │ ← Tela de loading (3s)
│ ANDAMENTO   │
└──────┬──────┘
       │ Timeout
       ↓
┌─────────────┐
│QUESTIONÁRIO │ ← Perguntas de saúde
│   SAÚDE     │
└──────┬──────┘
       │ Completo
       ↓
┌─────────────┐
│  ENDEREÇO   │ ← Coleta endereço de entrega
│             │
└──────┬──────┘
       │ Submit
       ↓
┌─────────────┐
│  SELEÇÃO    │ ← Escolhe dosagem do medicamento
│  DOSAGEM    │
└──────┬──────┘
       │ Selecionar
       ↓
┌─────────────┐
│ SOLICITAÇÃO │ ← Revisão de tudo
│   REVISÃO   │
└──────┬──────┘
       │ Confirmar
       ↓
┌─────────────┐
│ PAGAMENTO   │ ← Paga via PIX
│     PIX     │
└──────┬──────┘
       │ Pagamento OK
       ↓
┌─────────────┐
│  OBRIGADO   │ ← Confirmação + Protocolo
│   SUCESSO   │
└─────────────┘
```

---

## 🗺️ NAVEGAÇÃO

### Redirects Configurados

| De | Para | Tipo | Status |
|----|------|------|--------|
| `/` | `/cadastro` | Click botão | ✅ |
| `/cadastro` | `/validar-dados` | Submit form | ✅ |
| `/validar-dados` | `/validacao-em-andamento` | Auto | ✅ |
| `/validacao-em-andamento` | `/questionario-saude` | Timeout 3s | ✅ |
| `/questionario-saude` | `/endereco` | Submit | ✅ |
| `/endereco` | `/selecao` | Submit | ✅ CORRIGIDO |
| `/selecao` | `/solicitacao` | Click | ✅ |
| `/solicitacao` | `/pagamento_pix` | Click | ✅ |
| `/pagamento_pix` | `/obrigado` | Pagamento | ✅ CORRIGIDO |
| `/obrigado` | `/` | Click | ✨ NOVO |

### Navegação Reversa (Voltar)

- Questionário ← Anterior
- Endereço ← Questionário
- Seleção ← Endereço
- Solicitação ← Seleção
- Pagamento ← Solicitação
- Obrigado → Home

---

## 📚 DOCUMENTAÇÃO

O projeto inclui documentação completa:

1. **WORKFLOW.md** - Documentação detalhada de cada etapa do funil
   - Objetivo de cada página
   - Dados coletados
   - Navegação
   - Estados no localStorage

2. **NAVEGACAO_COMPLETA.md** - Mapa visual completo da navegação
   - Tabela de redirects
   - Fluxo ilustrado
   - Testes recomendados
   - Estatísticas

3. **RELATORIO_LIMPEZA.md** - Relatório de remoção de tracking
   - Facebook Pixel removido
   - Microsoft Clarity removido
   - Disable DevTools removido
   - 30 arquivos JS deletados
   - Links externos neutralizados

---

## ⭐ CARACTERÍSTICAS

### ✅ Funcionalidades

- ✓ Fluxo completo de cadastro a pagamento
- ✓ Validação de CPF com dados governamentais
- ✓ Questionário de elegibilidade médica
- ✓ Coleta de endereço com CEP automático
- ✓ Seleção de dosagem do medicamento
- ✓ Pagamento via PIX com QR Code
- ✓ Confirmação com número de protocolo

### 🔒 Segurança & Privacidade

- ✓ **0 scripts de tracking** (Facebook Pixel removido)
- ✓ **0 analytics externo** (Microsoft Clarity removido)
- ✓ **0 anti-debug** (Disable DevTools removido)
- ✓ **30 arquivos JS** de tracking deletados
- ✓ Links externos neutralizados
- ✓ Dados armazenados apenas localmente (localStorage)

### 💾 Persistência de Dados

| Dado | Armazenamento |
|------|---------------|
| CPF | localStorage |
| Nome completo | localStorage |
| Dados governamentais | localStorage |
| Respostas do questionário | localStorage |
| Endereço completo | localStorage |
| Dosagem selecionada | localStorage |
| Protocolo de validação | localStorage |

### 🎨 Design

- Interface seguindo padrões gov.br
- Fonte Rawline (oficial gov.br)
- Cores institucionais (#1351b4)
- Responsivo (mobile-first)
- Ícones Font Awesome

---

## 🚀 COMO USAR

### Desenvolvimento Local

1. **Clone ou baixe o projeto**
   ```bash
   cd /path/to/OFERTA\ MONJARO
   ```

2. **Inicie um servidor local**
   ```bash
   # Com Python 3
   python3 -m http.server 8000
   
   # Ou com Node.js
   npx http-server -p 8000
   
   # Ou com PHP
   php -S localhost:8000
   ```

3. **Acesse no navegador**
   ```
   http://localhost:8000
   ```

### Estrutura de URLs

- **Landing:** `http://localhost:8000/` ou `http://localhost:8000/index.html`
- **Cadastro:** `http://localhost:8000/cadastro/`
- **Validar:** `http://localhost:8000/validar-dados/`
- **Validação:** `http://localhost:8000/validacao-em-andamento/`
- **Questionário:** `http://localhost:8000/questionario-saude/`
- **Endereço:** `http://localhost:8000/endereco/`
- **Seleção:** `http://localhost:8000/selecao/`
- **Solicitação:** `http://localhost:8000/solicitacao/`
- **Pagamento:** `http://localhost:8000/pagamento_pix/`
- **Obrigado:** `http://localhost:8000/obrigado/`

---

## 📊 ESTATÍSTICAS

- **Total de Páginas:** 10
- **Linhas de Código HTML:** ~30.000
- **Arquivos JavaScript:** 5 (funcionais, sem tracking)
- **Arquivos de Recursos:** ~70 (imagens, CSS, fontes)
- **Tamanho Total:** ~11 MB
- **Tracking Scripts:** 0 ✅
- **Links Externos:** 0 (neutralizados) ✅

---

## ✨ CORREÇÕES REALIZADAS

### 1. Remoção Completa de Tracking
- ❌ Facebook Pixel (completamente removido)
- ❌ Microsoft Clarity (completamente removido)
- ❌ Disable DevTools (completamente removido)
- 🗑️ 30 arquivos JS de tracking deletados
- 🔒 ~29KB de código de tracking removido

### 2. Organização da Navegação
- ✅ Redirect `/endereco` → `/selecao` (corrigido)
- ✅ Redirect `/pagamento_pix` → `/obrigado` (corrigido)
- ✨ Página `/obrigado` criada (nova)

### 3. URLs Absolutos → Relativos
- Todos os redirects agora usam URLs relativas
- Sem dependência de domínio específico
- Funciona em qualquer ambiente

---

## 🎯 STATUS DO PROJETO

✅ **Navegação:** 100% funcional
✅ **Tracking:** 0% (completamente limpo)
✅ **Documentação:** Completa
✅ **Páginas:** Todas criadas
✅ **Testes:** Prontos para executar

---

## 🤝 SUPORTE

Para dúvidas ou problemas:

1. Consulte **WORKFLOW.md** para entender o fluxo
2. Verifique **NAVEGACAO_COMPLETA.md** para mapas de navegação
3. Leia **RELATORIO_LIMPEZA.md** para informações sobre tracking removido

---

## 📝 CHANGELOG

### v2.0.0 (Atual)
- ✅ Removido todo tracking (Facebook, Clarity, DevTools)
- ✅ Organizada navegação completa
- ✅ Criada página de obrigado
- ✅ Documentação completa
- ✅ URLs absolutos → relativos

### v1.0.0 (Original)
- Landing page funcional
- Funil de vendas básico
- Com tracking scripts

---

**🎉 PROJETO COMPLETO E PRONTO PARA USO!**

*Última atualização: 2024*
