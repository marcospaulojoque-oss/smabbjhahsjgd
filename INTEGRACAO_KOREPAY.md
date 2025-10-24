# Integração KorePay - Gateway de Pagamento PIX

Este documento descreve a integração completa com o gateway KorePay para pagamentos PIX no sistema Monjaro.

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Configuração](#configuração)
3. [Endpoints Implementados](#endpoints-implementados)
4. [Fluxo de Pagamento](#fluxo-de-pagamento)
5. [Estrutura de Dados](#estrutura-de-dados)
6. [Testes](#testes)
7. [Troubleshooting](#troubleshooting)
8. [Segurança](#segurança)

---

## 🎯 Visão Geral

A integração com KorePay permite:
- ✅ Geração de códigos PIX reais via API KorePay
- ✅ QR Codes funcionais para pagamento em apps bancários
- ✅ Verificação automática de status de pagamento
- ✅ Expiração configurável (1 dia por padrão)
- ✅ Suporte completo a EMV/BR Code padrão Banco Central

**API Base URL**: `https://api.korepay.com.br/functions/v1/`

**Documentação Oficial**: https://korepay.readme.io/reference/

---

## ⚙️ Configuração

### Requisitos

- Python 3.8+
- Acesso à internet (chamadas para API KorePay)
- Porta 8000 disponível (ou configurável)

### Credenciais KorePay

A API KorePay requer autenticação. Configure suas credenciais seguindo os passos:

1. **Criar conta em KorePay**:
   - Acesse https://korepay.com.br/
   - Complete o cadastro da empresa
   - Aguarde aprovação (1-2 dias úteis)

2. **Obter API Keys**:
   - Acesse o dashboard KorePay
   - Vá em: **Configurações > API Keys**
   - Copie suas chaves de API (teste e produção)

3. **Configurar no servidor** (quando necessário):
   ```python
   # Em proxy_api.py, adicione headers de autenticação
   headers={
       'Content-Type': 'application/json',
       'Accept': 'application/json',
       'Authorization': 'Bearer SEU_API_KEY_AQUI'  # Adicionar quando obtiver
   }
   ```

### Executar o Servidor

```bash
cd "/home/blacklotus/Downloads/OFERTA MONJARO"
python3 proxy_api.py
```

Servidor estará disponível em: `http://localhost:8000/`

---

## 🔌 Endpoints Implementados

### 1. POST `/processar_pagamento_mounjaro`

Cria uma nova transação PIX via KorePay.

**Request:**
```json
{
  "name": "João Silva",
  "email": "joao.silva@example.com",
  "phone": "11987654321",
  "cpf": "123.456.789-01",
  "amount": 197.90,
  "dosage": "5mg"
}
```

**Response (Sucesso):**
```json
{
  "success": true,
  "transaction_id": "txn_abc123xyz",
  "pix_code": "00020126580014br.gov.bcb.pix...",
  "pix_qrcode": "https://api.korepay.com.br/qrcode/...",
  "amount": 197.90,
  "status": "pending",
  "expires_at": "2025-10-18T23:59:59Z",
  "message": "PIX gerado com sucesso via KorePay",
  "korepay_raw": { ... }
}
```

**Response (Erro):**
```json
{
  "success": false,
  "error": "Mensagem de erro detalhada",
  "error_code": 400,
  "message": "Erro ao processar pagamento com KorePay"
}
```

**Mapeamento de Dados:**

| Campo Frontend | Campo KorePay API | Observações |
|----------------|-------------------|-------------|
| `name` | `customer.name` | Nome completo |
| `email` | `customer.email` | Email do cliente |
| `phone` | `customer.phone` | Apenas números (11987654321) |
| `cpf` | `customer.document.number` | Apenas números (12345678901) |
| `amount` | `amount` | Convertido para centavos (197.90 → 19790) |
| `dosage` | `items[0].title` | Ex: "Monjaro 5mg" |

---

### 2. GET `/check-payment-status/{transaction_id}`

Verifica o status atual de uma transação.

**Request:**
```
GET /check-payment-status/txn_abc123xyz
```

**Response:**
```json
{
  "success": true,
  "transaction_id": "txn_abc123xyz",
  "status": "completed",
  "amount": 197.90,
  "pix_code": "00020126580014br.gov.bcb.pix...",
  "timestamp": "2025-10-17T14:30:00Z",
  "paid": true,
  "message": "Pagamento concluído",
  "korepay_raw": { ... }
}
```

**Mapeamento de Status:**

| Status KorePay | Status Sistema | Descrição |
|----------------|----------------|-----------|
| `pending` | `pending` | Aguardando pagamento |
| `paid` | `completed` | Pagamento confirmado |
| `expired` | `failed` | PIX expirou |
| `cancelled` | `failed` | Pagamento cancelado |

---

## 🔄 Fluxo de Pagamento

### Diagrama de Sequência

```
Usuario           Frontend           proxy_api.py        KorePay API          Banco
  |                  |                    |                    |                 |
  |-- Preenche dados ---------------------->|                    |                 |
  |                  |                    |                    |                 |
  |                  |-- POST /processar --->|                    |                 |
  |                  |    pagamento         |                    |                 |
  |                  |                    |                    |                 |
  |                  |                    |-- POST /transactions ->|                 |
  |                  |                    |                    |                 |
  |                  |                    |<-- Retorna PIX code --|                 |
  |                  |                    |    + QR Code         |                 |
  |                  |                    |                    |                 |
  |                  |<-- Retorna dados PIX |                    |                 |
  |                  |                    |                    |                 |
  |<-- Mostra QR Code |                    |                    |                 |
  |    + Código PIX  |                    |                    |                 |
  |                  |                    |                    |                 |
  |-- Abre App Banco ------------------------------------------------->|
  |                  |                    |                    |                 |
  |-- Escaneia QR ------------------------------------------------->|
  |                  |                    |                    |                 |
  |-- Confirma pag. ------------------------------------------------->|
  |                  |                    |                    |                 |
  |                  |                    |                    |<-- Notifica pag. --|
  |                  |                    |                    |    confirmado   |
  |                  |                    |                    |                 |
  |                  |-- Polling (5s) ------>|                    |                 |
  |                  |                    |                    |                 |
  |                  |                    |-- GET /transactions/{id} ->|                 |
  |                  |                    |                    |                 |
  |                  |                    |<-- Status: paid ---|                 |
  |                  |                    |                    |                 |
  |                  |<-- Status: completed |                    |                 |
  |                  |                    |                    |                 |
  |<-- Redireciona para /obrigado          |                    |                 |
  |    (sucesso)     |                    |                    |                 |
```

### Passo a Passo Detalhado

**1. Usuário chega na página `/pagamento_pix`**
   - Frontend carrega dados do localStorage
   - Exibe resumo do pedido

**2. Frontend chama `/processar_pagamento_mounjaro`**
   - Envia dados do cliente + valor + produto
   - Aguarda resposta

**3. Backend (proxy_api.py) processa**
   - Recebe dados do frontend
   - Converte CPF/telefone (remove formatação)
   - Converte valor para centavos
   - Monta payload KorePay

**4. Backend chama API KorePay**
   - POST para `https://api.korepay.com.br/functions/v1/transactions`
   - Recebe código PIX + QR Code real

**5. Backend retorna para frontend**
   - Código PIX (string EMV/BR Code)
   - URL do QR Code (imagem PNG)
   - Transaction ID (para polling)
   - Data de expiração

**6. Frontend exibe PIX**
   - Mostra QR Code
   - Mostra código PIX (botão copiar)
   - Inicia timer de 30 minutos
   - Inicia polling a cada 5 segundos

**7. Polling de Status**
   - A cada 5 segundos: GET `/check-payment-status/{id}`
   - Se status = "completed": redireciona para `/obrigado`
   - Se status = "failed": mostra erro
   - Se timer expira: para polling, redireciona para `/selecao`

**8. Pagamento confirmado**
   - KorePay detecta pagamento no banco
   - Atualiza status para "paid"
   - Próximo polling detecta: redireciona para sucesso

---

## 📊 Estrutura de Dados

### Payload Enviado para KorePay

```javascript
{
  "customer": {
    "name": "João Silva",              // Nome completo
    "email": "joao@example.com",       // Email válido
    "phone": "11987654321",            // Apenas números
    "document": {
      "number": "12345678901",         // CPF apenas números
      "type": "CPF"                     // Tipo de documento
    }
  },
  "paymentMethod": "PIX",              // Sempre "PIX"
  "amount": 19790,                     // Valor em centavos (197.90 → 19790)
  "items": [
    {
      "title": "Monjaro 5mg",          // Descrição do produto
      "unitPrice": 19790,              // Preço unitário em centavos
      "quantity": 1                     // Quantidade
    }
  ],
  "pix": {
    "expiresInDays": 1                 // Expira em 1 dia
  }
}
```

### Resposta da KorePay (Exemplo)

```javascript
{
  "id": "txn_1234567890abcdef",
  "status": "pending",
  "amount": 19790,
  "currency": "BRL",
  "customer": {
    "name": "João Silva",
    "email": "joao@example.com",
    "document": {
      "type": "CPF",
      "number": "12345678901"
    }
  },
  "pix": {
    "code": "00020126580014br.gov.bcb.pix0136korepay.com.br/pix/v2/txn_1234567890abcdef5204000053039865802BR5925Programa Monjaro6009SAO PAULO62070503***63041D3D",
    "qrCode": "https://api.korepay.com.br/qrcode/txn_1234567890abcdef.png",
    "expiresAt": "2025-10-18T23:59:59.000Z"
  },
  "createdAt": "2025-10-17T10:30:00.000Z",
  "updatedAt": "2025-10-17T10:30:00.000Z"
}
```

### Resposta Padronizada (Sistema)

```javascript
{
  "success": true,
  "transaction_id": "txn_1234567890abcdef",
  "pix_code": "00020126580014br.gov.bcb.pix...",
  "pix_qrcode": "https://api.korepay.com.br/qrcode/...",
  "amount": 197.90,
  "status": "pending",
  "expires_at": "2025-10-18T23:59:59Z",
  "message": "PIX gerado com sucesso via KorePay",
  "korepay_raw": { ... }  // Resposta completa da KorePay (para debug)
}
```

---

## 🧪 Testes

### Teste 1: Gerar PIX via cURL

```bash
curl --request POST \
     --url http://localhost:8000/processar_pagamento_mounjaro \
     --header 'Content-Type: application/json' \
     --data '{
       "name": "João Silva",
       "email": "joao.silva@example.com",
       "phone": "11987654321",
       "cpf": "12345678901",
       "amount": 197.90,
       "dosage": "5mg"
     }'
```

**Resultado Esperado:**
- HTTP 200 OK
- JSON com `transaction_id`, `pix_code`, `pix_qrcode`
- Logs no servidor: `✅ [KOREPAY] PIX gerado com sucesso`

### Teste 2: Verificar Status

```bash
curl --request GET \
     --url http://localhost:8000/check-payment-status/txn_1234567890abcdef
```

**Resultado Esperado:**
- HTTP 200 OK
- JSON com `status: "pending"` ou `"completed"`

### Teste 3: Fluxo Completo no Frontend

1. Acesse: `http://localhost:8000/`
2. Preencha o formulário de cadastro (CPF: `046.891.496-07`)
3. Complete questionário de saúde
4. Preencha endereço
5. Selecione dosagem
6. Clique em "Gerar PIX"
7. Verifique se QR Code aparece
8. Verifique se código PIX pode ser copiado
9. Abra console do navegador (F12)
10. Observe logs de polling: `[PAYMENT POLLING] Checking status...`

### Teste 4: Código PIX Real

Para validar se o código PIX é real:

1. Gere um PIX pelo sistema
2. Copie o código PIX
3. Abra o app do seu banco
4. Vá em "Pix" > "Pix Copia e Cola"
5. Cole o código
6. **Deve mostrar**: Programa Monjaro, valor R$ 197,90, São Paulo

⚠️ **ATENÇÃO**: Não complete o pagamento em ambiente de teste! Use apenas para validar que o código é reconhecido pelo banco.

---

## 🔧 Troubleshooting

### Erro: "Erro ao processar pagamento com KorePay"

**Causa**: API KorePay retornou erro.

**Soluções**:
1. Verifique logs do servidor para ver erro detalhado
2. Confirme que API Key está configurada (se aplicável)
3. Verifique se payload está correto
4. Teste credenciais em ambiente de sandbox primeiro

**Logs para verificar**:
```
❌ [KOREPAY] HTTPError: 401 - Unauthorized
📋 [KOREPAY] Erro detalhado: {"message": "Invalid API key"}
```

### Erro: "Transação não encontrada" (404)

**Causa**: Transaction ID inválido ou não existe.

**Soluções**:
1. Verifique se transaction_id foi salvo corretamente no localStorage
2. Confirme que transaction_id retornado na criação está correto
3. Verifique se transação não expirou

### QR Code não carrega

**Causa**: URL do QR Code inválida ou CORS.

**Soluções**:
1. Verifique se `pix_qrcode` contém URL válida
2. Teste URL diretamente no navegador
3. Se CORS, considere fazer proxy da imagem

### Polling não para quando pago

**Causa**: Status não está sendo mapeado corretamente.

**Soluções**:
1. Verifique logs: `✅ [KOREPAY] Status: completed`
2. Confirme mapeamento de status em `handle_check_payment_status()`
3. Verifique condição no frontend: `if (data.status === 'completed')`

### Timer expira imediatamente

**Causa**: `expires_at` não está sendo parseado corretamente.

**Soluções**:
1. Verifique formato de data retornado pela KorePay
2. Confirme que conversão para timestamp está correta
3. Use `console.log()` para debugar cálculo de tempo restante

---

## 🔒 Segurança

### ✅ Implementações de Segurança

1. **HTTPS Obrigatório em Produção**
   - Dados sensíveis (CPF, email) devem trafegar criptografados
   - Configure certificado SSL/TLS

2. **Validação de Dados**
   ```python
   # Remover formatação (evitar injection)
   cpf = cpf.replace('.', '').replace('-', '')
   phone = phone.replace('(', '').replace(')', '').replace('-', '').replace(' ', '')
   ```

3. **Timeout de Requisições**
   ```python
   urllib.request.urlopen(req, timeout=30)  # 30 segundos
   ```

4. **Logs de Auditoria**
   - Todas as transações são logadas
   - Timestamp + Transaction ID + Valor
   - Útil para reconciliação financeira

5. **Headers CORS Configurados**
   - `Access-Control-Allow-Origin: *` (desenvolvimento)
   - Em produção: restringir para domínio específico

### ⚠️ Vulnerabilidades a Corrigir em Produção

1. **API Key Hardcoded**
   - ❌ Nunca comitar API keys no código
   - ✅ Usar variáveis de ambiente:
     ```python
     import os
     api_key = os.environ.get('KOREPAY_API_KEY')
     ```

2. **Sem Rate Limiting**
   - ❌ Alguém pode fazer múltiplas requisições
   - ✅ Implementar limite: 10 requisições/minuto por IP

3. **Sem Validação de Valor**
   - ❌ Frontend pode enviar valor manipulado
   - ✅ Recalcular valor no backend baseado em dosagem

4. **localStorage não é seguro**
   - ❌ Dados sensíveis ficam expostos
   - ✅ Usar backend real com sessões

5. **Sem Webhook**
   - ❌ Depende de polling (ineficiente)
   - ✅ Implementar webhook KorePay para notificação instantânea

### 🔐 Checklist de Segurança para Produção

- [ ] Mover API keys para variáveis de ambiente
- [ ] Implementar HTTPS (certificado SSL)
- [ ] Adicionar rate limiting (10 req/min)
- [ ] Validar e sanitizar todos os inputs
- [ ] Recalcular valores no backend
- [ ] Implementar webhook KorePay
- [ ] Adicionar autenticação de usuário
- [ ] Usar banco de dados real (PostgreSQL/MySQL)
- [ ] Configurar CORS para domínio específico
- [ ] Implementar logs estruturados (JSON)
- [ ] Configurar monitoramento (Sentry, Datadog)
- [ ] Fazer backup regular de transações
- [ ] Implementar retry logic para falhas de rede
- [ ] Adicionar testes automatizados
- [ ] Documentar procedimento de rollback

---

## 📚 Referências

- **Documentação KorePay**: https://korepay.readme.io/reference/
- **Especificação EMV PIX**: https://www.bcb.gov.br/estabilidadefinanceira/pix
- **Python urllib**: https://docs.python.org/3/library/urllib.request.html
- **CORS**: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS

---

## 📝 Changelog

### v1.0.0 (2025-10-17)
- ✅ Integração completa com API KorePay
- ✅ Endpoint de criação de transação
- ✅ Endpoint de verificação de status
- ✅ Mapeamento de status KorePay → Sistema
- ✅ Tratamento de erros robusto
- ✅ Logs detalhados com prefixo [KOREPAY]
- ✅ Documentação completa

---

## 🆘 Suporte

**Issues**: Criar issue detalhada com:
- Logs do servidor (copiar terminal)
- Request/Response completos
- Passos para reproduzir
- Screenshot (se aplicável)

**Email de Suporte KorePay**: suporte@korepay.com.br

---

**Última atualização**: 2025-10-17
**Versão**: 1.0.0
**Autor**: Sistema Monjaro - Integração PIX
