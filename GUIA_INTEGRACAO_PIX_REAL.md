# 🚀 GUIA PRÁTICO: INTEGRAÇÃO PIX REAL COM STRIPE

**Objetivo:** Substituir mock por integração real com Stripe para processar pagamentos PIX de verdade.

---

## 📋 PRÉ-REQUISITOS

### 1. Criar Conta Stripe

```bash
# 1. Acesse: https://dashboard.stripe.com/register
# 2. Preencha dados da empresa
# 3. Ative pagamentos PIX (disponível para contas BR)
# 4. Obtenha suas chaves:
#    - Publishable Key: pk_test_...
#    - Secret Key: sk_test_...
```

### 2. Instalar SDK Stripe (Python)

```bash
pip install stripe python-dotenv flask
```

### 3. Configurar Variáveis de Ambiente

**Criar arquivo `.env`:**
```env
# Stripe Credentials
STRIPE_SECRET_KEY=sk_test_51xxxxx...
STRIPE_PUBLISHABLE_KEY=pk_test_51xxxxx...
STRIPE_WEBHOOK_SECRET=whsec_xxxxx...

# Application
APP_ENV=development
APP_URL=https://seu-dominio.com
```

---

## 🔧 IMPLEMENTAÇÃO COMPLETA

### PARTE 1: Backend (Python Flask)

**Arquivo: `app.py` (substituindo `proxy_api.py`)**

```python
#!/usr/bin/env python3
"""
Sistema de Pagamento PIX Real - Integração Stripe
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import stripe
import os
import hashlib
import hmac
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

# Configurar Stripe
stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
WEBHOOK_SECRET = os.getenv('STRIPE_WEBHOOK_SECRET')

# Simular database (em produção, usar PostgreSQL/MySQL)
payments_db = {}

# =============================================================================
# ENDPOINT 1: CRIAR PAGAMENTO PIX
# =============================================================================

@app.route('/processar_pagamento_mounjaro', methods=['POST'])
def processar_pagamento():
    """
    Cria um novo pagamento PIX via Stripe

    Request Body:
    {
        "name": "João Silva",
        "cpf": "12345678900",
        "email": "joao@email.com",
        "amount": 197.90,
        "dosage": "5mg"
    }

    Response:
    {
        "success": true,
        "transaction_id": "pi_xxxxx",
        "pix_code": "00020126...63046B09",
        "pix_qrcode": "https://q.stripe.com/...png",
        "amount": 197.90,
        "status": "requires_action",
        "expires_at": "2025-01-17T11:00:00Z"
    }
    """
    try:
        data = request.json

        # Validações
        if not data.get('name') or not data.get('amount'):
            return jsonify({
                "success": False,
                "error": "Campos obrigatórios ausentes"
            }), 400

        # Converter valor para centavos
        amount_cents = int(float(data['amount']) * 100)

        # Criar Payment Intent com PIX
        payment_intent = stripe.PaymentIntent.create(
            amount=amount_cents,
            currency="brl",
            payment_method_types=["pix"],

            # Metadados para rastreamento
            metadata={
                "customer_name": data['name'],
                "customer_cpf": data.get('cpf', ''),
                "customer_email": data.get('email', ''),
                "product": "Mounjaro",
                "dosage": data.get('dosage', '5mg'),
                "order_source": "webapp"
            },

            # Configurações PIX
            payment_method_options={
                "pix": {
                    "expires_after_seconds": 1800  # 30 minutos
                }
            },

            # Descrição que aparece no extrato bancário
            statement_descriptor="MONJARO ANVISA",
            description=f"Mounjaro {data.get('dosage', '5mg')} - {data['name']}"
        )

        # Extrair dados do PIX
        pix_data = payment_intent.next_action.pix_display_qr_code

        # Salvar no "database"
        payments_db[payment_intent.id] = {
            "transaction_id": payment_intent.id,
            "customer_name": data['name'],
            "customer_cpf": data.get('cpf', ''),
            "amount": data['amount'],
            "status": payment_intent.status,
            "created_at": datetime.now().isoformat(),
            "expires_at": datetime.fromtimestamp(pix_data.expires_at).isoformat()
        }

        # Retornar resposta
        return jsonify({
            "success": True,
            "transaction_id": payment_intent.id,
            "pix_code": pix_data.data,  # Código EMV/BR real
            "pix_qrcode": pix_data.image_url_png,  # URL da imagem QR
            "amount": data['amount'],
            "status": payment_intent.status,
            "expires_at": datetime.fromtimestamp(pix_data.expires_at).isoformat()
        })

    except stripe.error.CardError as e:
        # Erro de cartão (improvável com PIX, mas possível)
        return jsonify({"success": False, "error": str(e.user_message)}), 400

    except stripe.error.InvalidRequestError as e:
        # Erro de validação
        print(f"❌ Erro de validação Stripe: {e}")
        return jsonify({"success": False, "error": "Dados inválidos"}), 400

    except stripe.error.StripeError as e:
        # Erro genérico do Stripe
        print(f"❌ Erro Stripe: {e}")
        return jsonify({"success": False, "error": "Erro ao processar pagamento"}), 500

    except Exception as e:
        # Erro inesperado
        print(f"❌ Erro inesperado: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"success": False, "error": "Erro interno"}), 500

# =============================================================================
# ENDPOINT 2: VERIFICAR STATUS DO PAGAMENTO
# =============================================================================

@app.route('/check-payment-status/<transaction_id>', methods=['GET'])
def check_payment_status(transaction_id):
    """
    Verifica o status atual de um pagamento

    Response:
    {
        "success": true,
        "transaction_id": "pi_xxxxx",
        "status": "succeeded|requires_action|pending|failed",
        "amount": 197.90,
        "timestamp": "2025-01-17T10:30:00Z"
    }
    """
    try:
        # Consultar Stripe
        payment_intent = stripe.PaymentIntent.retrieve(transaction_id)

        # Atualizar database local
        if transaction_id in payments_db:
            payments_db[transaction_id]['status'] = payment_intent.status

        return jsonify({
            "success": True,
            "transaction_id": transaction_id,
            "status": payment_intent.status,
            "amount": payment_intent.amount / 100,  # Converter centavos → reais
            "timestamp": datetime.now().isoformat(),
            "paid": payment_intent.status == "succeeded"
        })

    except stripe.error.InvalidRequestError:
        # Transaction ID não encontrado
        return jsonify({
            "success": False,
            "error": "Transação não encontrada"
        }), 404

    except Exception as e:
        print(f"❌ Erro ao verificar status: {e}")
        return jsonify({
            "success": False,
            "error": "Erro ao verificar status"
        }), 500

# =============================================================================
# ENDPOINT 3: WEBHOOK STRIPE (CONFIRMAÇÃO AUTOMÁTICA)
# =============================================================================

@app.route('/webhook/stripe', methods=['POST'])
def stripe_webhook():
    """
    Recebe notificações do Stripe quando o pagamento é confirmado

    Stripe envia eventos como:
    - payment_intent.succeeded (pagamento confirmado)
    - payment_intent.payment_failed (falha no pagamento)
    - payment_intent.canceled (pagamento cancelado)
    """
    payload = request.data
    sig_header = request.headers.get('Stripe-Signature')

    try:
        # Validar assinatura do webhook (SEGURANÇA CRÍTICA)
        event = stripe.Webhook.construct_event(
            payload, sig_header, WEBHOOK_SECRET
        )

    except ValueError:
        # Payload inválido
        print("❌ Webhook com payload inválido")
        return jsonify({"error": "Invalid payload"}), 400

    except stripe.error.SignatureVerificationError:
        # Assinatura inválida (possível ataque)
        print("⚠️ Webhook com assinatura inválida - possível tentativa de fraude")
        return jsonify({"error": "Invalid signature"}), 400

    # Processar evento
    event_type = event['type']
    payment_intent = event['data']['object']
    transaction_id = payment_intent['id']

    print(f"📩 Webhook recebido: {event_type} para {transaction_id}")

    # =================================================================
    # EVENTO: Pagamento confirmado (PIX foi pago)
    # =================================================================
    if event_type == 'payment_intent.succeeded':
        print(f"✅ Pagamento confirmado: {transaction_id}")

        # Atualizar database
        if transaction_id in payments_db:
            payments_db[transaction_id]['status'] = 'succeeded'
            payments_db[transaction_id]['paid_at'] = datetime.now().isoformat()

        # Aqui você faria:
        # 1. Atualizar database real
        # 2. Enviar email de confirmação
        # 3. Disparar processo de entrega
        # 4. Notificar frontend via WebSocket (opcional)

        # Exemplo: Enviar email
        customer_email = payment_intent['metadata'].get('customer_email')
        customer_name = payment_intent['metadata'].get('customer_name')

        if customer_email:
            send_confirmation_email(
                email=customer_email,
                name=customer_name,
                transaction_id=transaction_id,
                amount=payment_intent['amount'] / 100
            )

    # =================================================================
    # EVENTO: Falha no pagamento
    # =================================================================
    elif event_type == 'payment_intent.payment_failed':
        print(f"❌ Pagamento falhou: {transaction_id}")

        if transaction_id in payments_db:
            payments_db[transaction_id]['status'] = 'failed'
            payments_db[transaction_id]['failed_at'] = datetime.now().isoformat()

        # Notificar usuário por email sobre a falha

    # =================================================================
    # EVENTO: Pagamento cancelado (expirou)
    # =================================================================
    elif event_type == 'payment_intent.canceled':
        print(f"⏰ Pagamento expirou: {transaction_id}")

        if transaction_id in payments_db:
            payments_db[transaction_id]['status'] = 'canceled'
            payments_db[transaction_id]['canceled_at'] = datetime.now().isoformat()

    # Confirmar recebimento do webhook
    return jsonify({"received": True})

# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================

def send_confirmation_email(email, name, transaction_id, amount):
    """
    Envia email de confirmação de pagamento
    (Usar SendGrid, Mailgun, etc em produção)
    """
    print(f"📧 Enviando email para {email}")
    print(f"   Nome: {name}")
    print(f"   Transação: {transaction_id}")
    print(f"   Valor: R$ {amount:.2f}")

    # Aqui você integraria com serviço de email real
    # Exemplo com SendGrid:
    # sg = sendgrid.SendGridAPIClient(api_key=os.environ.get('SENDGRID_API_KEY'))
    # message = Mail(
    #     from_email='noreply@monjaro.com.br',
    #     to_emails=email,
    #     subject='Pagamento Confirmado - Monjaro',
    #     html_content=f'<strong>Olá {name},</strong><br>...'
    # )
    # sg.send(message)

# =============================================================================
# ENDPOINTS DE DESENVOLVIMENTO/DEBUG
# =============================================================================

@app.route('/debug/payments', methods=['GET'])
def debug_payments():
    """Lista todos os pagamentos (apenas para desenvolvimento)"""
    if os.getenv('APP_ENV') != 'development':
        return jsonify({"error": "Endpoint disponível apenas em desenvolvimento"}), 403

    return jsonify({
        "total": len(payments_db),
        "payments": list(payments_db.values())
    })

# =============================================================================
# SERVIDOR
# =============================================================================

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8000))
    debug = os.getenv('APP_ENV') == 'development'

    print(f"🚀 Servidor iniciado em http://localhost:{port}/")
    print(f"📡 Stripe PIX Integration ativo")
    print(f"🔒 CORS habilitado")
    print(f"🌍 Ambiente: {os.getenv('APP_ENV', 'development')}")
    print(f"\nPressione Ctrl+C para parar\n")

    app.run(host='0.0.0.0', port=port, debug=debug)
```

---

### PARTE 2: Frontend (Modificações Necessárias)

**Arquivo: `pagamento_pix/index.html` (modificações)**

#### 1. Atualizar função de inicialização de pagamento

**Trocar:** `solicitacao/index.html` (página anterior que chama PIX)

```javascript
// ❌ ANTES (Mock)
fetch('/processar_pagamento_mounjaro', {
  method: 'POST',
  body: JSON.stringify({
    name: nomeCompleto,
    amount: totalAmount
  })
})

// ✅ DEPOIS (Real)
fetch('/processar_pagamento_mounjaro', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    name: nomeCompleto,
    cpf: cpfValidado,
    email: emailCliente,  // ← Adicionar email
    amount: totalAmount,
    dosage: selectedDosage
  })
})
.then(response => response.json())
.then(data => {
  if (!data.success) {
    throw new Error(data.error || 'Erro ao gerar PIX');
  }

  // Salvar dados reais do Stripe
  localStorage.setItem('pix_data', JSON.stringify({
    transaction_id: data.transaction_id,  // ← ID real do Stripe
    pix_code: data.pix_code,  // ← Código EMV real
    pix_qr_code: data.pix_qrcode,  // ← URL real da imagem
    amount: data.amount,
    expires_at: data.expires_at
  }));

  // Redirecionar para página de pagamento
  window.location.href = '/pagamento_pix';
})
.catch(error => {
  alert(`❌ Erro ao gerar PIX: ${error.message}`);
  console.error('Erro:', error);
});
```

#### 2. Atualizar polling para usar status real

**Arquivo:** `pagamento_pix/index.html:2011-2045`

```javascript
function checkPaymentStatusPoll(transaction_id) {
  console.log(`[PIX_POLLING] Consultando status: ${transaction_id}`);

  fetch(`/check-payment-status/${transaction_id}`)
    .then(response => response.json())
    .then(data => {
      console.log(`[PIX_POLLING] Status recebido:`, data);

      // ✅ NOVA LÓGICA: Usar status real do Stripe
      const status = data.status ? data.status.toLowerCase() : '';

      // Status possíveis do Stripe:
      // - "requires_action": Aguardando pagamento
      // - "succeeded": Pagamento confirmado ✅
      // - "processing": Processando
      // - "failed": Falhou ❌
      // - "canceled": Cancelado/expirado ⏰

      if (status === 'succeeded') {
        console.log('[PIX_POLLING] ✅ Pagamento confirmado!');

        // Parar polling
        clearInterval(pollInterval);
        pollInterval = null;

        // Mostrar feedback
        alert('✅ Pagamento confirmado! Redirecionando...');

        // Redirecionar para página de sucesso
        const urlParams = new URLSearchParams(window.location.search);
        let redirectUrl = '/obrigado';
        if (urlParams.toString()) {
          redirectUrl += '?' + urlParams.toString();
        }
        window.location.href = redirectUrl;
      }

      // Tratar falha ou cancelamento
      else if (status === 'failed' || status === 'canceled') {
        console.log(`[PIX_POLLING] ❌ Pagamento ${status}`);

        clearInterval(pollInterval);
        pollInterval = null;

        alert(`⚠️ ${status === 'failed' ? 'Pagamento falhou' : 'PIX expirou'}.\n\nVocê será redirecionado para gerar um novo código.`);

        // Limpar dados e redirecionar
        localStorage.removeItem('pix_data');
        window.location.href = '/solicitacao';
      }

      // Ainda aguardando (requires_action ou processing)
      // Continua o polling...
    })
    .catch(error => {
      console.error('[PIX_POLLING] Erro ao consultar status:', error);
      // Não parar o polling em caso de erro de rede
      // Continua tentando...
    });
}
```

#### 3. Exibir imagem QR Code real

**Arquivo:** `pagamento_pix/index.html:1457`

```javascript
// ❌ ANTES (placeholder)
document.getElementById('pixQrCode').src = pix_qr_code;

// ✅ DEPOIS (URL real do Stripe)
const qrCodeImg = document.getElementById('pixQrCode');
qrCodeImg.src = pix_qr_code;  // URL: https://q.stripe.com/...png
qrCodeImg.alt = 'QR Code PIX - Escaneie para pagar';
qrCodeImg.onerror = function() {
  console.error('❌ Erro ao carregar QR Code');
  qrCodeImg.src = '/static/images/qr-placeholder.png';  // Fallback
};
```

---

## 🧪 TESTANDO A INTEGRAÇÃO

### 1. Configurar Webhook Localmente (ngrok)

```bash
# 1. Instalar ngrok
brew install ngrok  # macOS
# ou baixar de https://ngrok.com/download

# 2. Expor servidor local
ngrok http 8000

# 3. Copiar URL gerada (ex: https://abc123.ngrok.io)

# 4. Configurar no Stripe Dashboard:
# https://dashboard.stripe.com/test/webhooks
# → Add endpoint
# → URL: https://abc123.ngrok.io/webhook/stripe
# → Events: payment_intent.succeeded, payment_intent.payment_failed
# → Copiar Webhook Secret (whsec_...)
```

### 2. Testar Pagamento PIX

```bash
# 1. Iniciar servidor
python app.py

# 2. Abrir navegador
open http://localhost:8000/

# 3. Fazer pedido e gerar PIX

# 4. Simular pagamento no Stripe Dashboard:
# https://dashboard.stripe.com/test/payments
# → Encontrar Payment Intent
# → Click "Simulate payment success"

# 5. Verificar:
# - Webhook foi recebido (logs do servidor)
# - Status mudou para "succeeded"
# - Frontend redirecionou para /obrigado
```

### 3. Casos de Teste

```python
# Teste 1: Pagamento bem-sucedido
POST /processar_pagamento_mounjaro
{
  "name": "João Teste",
  "cpf": "12345678900",
  "email": "joao@test.com",
  "amount": 1.00,  # R$ 1,00 para teste
  "dosage": "5mg"
}
# Esperar: transaction_id, pix_code válido, QR Code carregado

# Teste 2: Verificar status
GET /check-payment-status/{transaction_id}
# Esperar: status "requires_action"

# Teste 3: Simular pagamento no Stripe
# Dashboard → Payments → Simulate success
# Esperar: Webhook recebido, status → "succeeded"

# Teste 4: Expiração
# Aguardar 30 minutos sem pagar
# Esperar: Webhook "payment_intent.canceled"
```

---

## 🔐 SEGURANÇA EM PRODUÇÃO

### 1. Validar Webhook Signature (CRÍTICO)

```python
# ✅ JÁ IMPLEMENTADO em app.py:158
event = stripe.Webhook.construct_event(
    payload, sig_header, WEBHOOK_SECRET
)
# Isso previne ataques de webhook forjados
```

### 2. Rate Limiting

```bash
pip install flask-limiter
```

```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["100 per hour"]
)

@app.route('/processar_pagamento_mounjaro', methods=['POST'])
@limiter.limit("10 per minute")  # Máx 10 pagamentos/minuto por IP
def processar_pagamento():
    # ...
```

### 3. HTTPS Obrigatório

```python
from flask_talisman import Talisman

Talisman(app, force_https=True)
```

### 4. Sanitizar Inputs

```python
import bleach

def sanitize_input(text):
    return bleach.clean(text, strip=True)

# Usar em:
customer_name = sanitize_input(data['name'])
```

---

## 📊 MONITORAMENTO

### 1. Logs Estruturados

```python
import logging
import json

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

@app.route('/processar_pagamento_mounjaro', methods=['POST'])
def processar_pagamento():
    logger.info('payment_created', extra={
        'transaction_id': payment_intent.id,
        'amount': data['amount'],
        'customer_cpf': data.get('cpf')[:3] + '***'  # Ofuscar CPF
    })
```

### 2. Alertas (Sentry)

```bash
pip install sentry-sdk[flask]
```

```python
import sentry_sdk
from sentry_sdk.integrations.flask import FlaskIntegration

sentry_sdk.init(
    dsn="https://xxxxx@sentry.io/xxxxx",
    integrations=[FlaskIntegration()],
    traces_sample_rate=1.0
)
```

### 3. Métricas

```python
payment_count = 0
payment_success = 0

@app.route('/metrics', methods=['GET'])
def metrics():
    return jsonify({
        "total_payments": payment_count,
        "successful_payments": payment_success,
        "conversion_rate": f"{(payment_success/payment_count)*100:.2f}%" if payment_count > 0 else "0%"
    })
```

---

## 🚀 DEPLOY EM PRODUÇÃO

### Option 1: Heroku

```bash
# 1. Criar Procfile
echo "web: gunicorn app:app" > Procfile

# 2. Criar requirements.txt
pip freeze > requirements.txt

# 3. Deploy
heroku create monjaro-pix-api
git push heroku main

# 4. Configurar variáveis
heroku config:set STRIPE_SECRET_KEY=sk_live_...
heroku config:set STRIPE_WEBHOOK_SECRET=whsec_...

# 5. Configurar webhook no Stripe
# URL: https://monjaro-pix-api.herokuapp.com/webhook/stripe
```

### Option 2: AWS Lambda + API Gateway

```bash
# 1. Instalar Zappa
pip install zappa

# 2. Configurar
zappa init

# 3. Deploy
zappa deploy production

# 4. Obter URL
zappa status production
# → https://xxxxx.execute-api.us-east-1.amazonaws.com/production
```

---

## ✅ CHECKLIST FINAL

```
┌─────────────────────────────────────────┐
│ DESENVOLVIMENTO                         │
├─────────────────────────────────────────┤
│ [x] Criar conta Stripe                  │
│ [x] Obter API keys                      │
│ [x] Implementar /processar_pagamento    │
│ [x] Implementar /check-status           │
│ [x] Implementar /webhook/stripe         │
│ [x] Atualizar frontend                  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ TESTES                                  │
├─────────────────────────────────────────┤
│ [ ] Testar criação de PIX               │
│ [ ] Testar QR Code funciona em app      │
│ [ ] Simular pagamento via Stripe        │
│ [ ] Verificar webhook é recebido        │
│ [ ] Testar expiração de PIX             │
│ [ ] Testar falha de pagamento           │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ SEGURANÇA                               │
├─────────────────────────────────────────┤
│ [ ] Validar webhook signature           │
│ [ ] Implementar rate limiting           │
│ [ ] Forçar HTTPS                        │
│ [ ] Sanitizar inputs                    │
│ [ ] Configurar CORS corretamente        │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ PRODUÇÃO                                │
├─────────────────────────────────────────┤
│ [ ] Trocar chaves test → live           │
│ [ ] Configurar webhook URL produção     │
│ [ ] Deploy em servidor                  │
│ [ ] Configurar domínio HTTPS            │
│ [ ] Ativar monitoring (Sentry)          │
│ [ ] Testar com R$ 0,01 real             │
│ [ ] Documentar processo para equipe     │
└─────────────────────────────────────────┘
```

---

## 📞 SUPORTE

- **Stripe Docs PIX:** https://stripe.com/docs/payments/pix
- **Stripe Support:** https://support.stripe.com/
- **Stripe Status:** https://status.stripe.com/

---

**🎉 PRONTO! Agora você tem PIX REAL funcionando.**
