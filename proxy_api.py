#!/usr/bin/env python3
"""
Proxy simples para resolver problemas de CORS com a API de CPF
"""
from http.server import HTTPServer, SimpleHTTPRequestHandler
import json
import urllib.request
import urllib.parse
from urllib.error import HTTPError
import base64

# ==========================================
# 🔐 CREDENCIAIS DO GATEWAY DE PAGAMENTO
# ==========================================
# KorePay API Credentials
KOREPAY_SECRET_KEY = "sk_live_YOUR_SECRET_KEY_HERE"
KOREPAY_RANDOM_KEY = "YOUR_RANDOM_KEY_HERE"

# ⚠️ MODO DE SIMULAÇÃO (para desenvolvimento)
# Define como True para usar PIX simulado quando credenciais reais falharem
KOREPAY_SIMULATION_MODE = False  # ✅ DESATIVADO - Credenciais válidas configuradas!

# IMPORTANTE: Para produção, mova estas credenciais para variáveis de ambiente:
# import os
# KOREPAY_SECRET_KEY = os.environ.get('KOREPAY_SECRET_KEY', '')
# KOREPAY_RANDOM_KEY = os.environ.get('KOREPAY_RANDOM_KEY', '')
# ==========================================

def create_basic_auth_header(api_key):
    """
    Cria header de autenticação HTTP Basic Auth
    Username: API Key
    Password: vazio
    """
    # Formato: "api_key:" (password vazio)
    credentials = f"{api_key}:"
    # Codificar em base64
    encoded = base64.b64encode(credentials.encode('utf-8')).decode('utf-8')
    return f"Basic {encoded}"

class CORSRequestHandler(SimpleHTTPRequestHandler):
    
    def end_headers(self):
        # Adicionar headers CORS
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        SimpleHTTPRequestHandler.end_headers(self)
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()
    
    def do_GET(self):
        # Tratar requisições para API de CPF
        if self.path.startswith('/api/consultar-cpf?'):
            self.handle_cpf_api()
        # Tratar requisições para APIs que não existem
        elif self.path.startswith('/api/farmacias-por-ip'):
            self.handle_mock_farmacias()
        elif self.path.startswith('/api/ip-geo'):
            self.handle_mock_geo()
        elif self.path.startswith('/api/buscar-servicos-saude/'):
            self.handle_buscar_servicos_saude()
        # 🔥 NOVO: Endpoint para verificar status de pagamento
        elif self.path.startswith('/check-payment-status/'):
            self.handle_check_payment_status()
        else:
            # Servir arquivos estáticos
            super().do_GET()
    
    def do_POST(self):
        # Tratar POST para API de CPF
        if self.path == '/api/consultar-cpf':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            cpf = data.get('cpf', '')
            self.handle_cpf_api_with_cpf(cpf)
        # 🔥 CORREÇÃO: Adicionar endpoint para calcular preço
        elif self.path == '/api/calcular-preco':
            self.handle_calcular_preco()
        # 🔥 NOVO: Endpoint para processar pagamento Mounjaro
        elif self.path == '/processar_pagamento_mounjaro':
            self.handle_processar_pagamento()
        else:
            self.send_error(404)
    
    def handle_cpf_api(self):
        """Proxy para API de CPF"""
        try:
            # Extrair CPF da query string
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            cpf = params.get('cpf', [''])[0]

            if not cpf:
                self.send_error(400, "CPF não fornecido")
                return

            # Fazer requisição para API real
            api_token = "e3bd2312d93dca38d2003095196a09c2"
            api_url = f"https://apidecpf.site/api-v1/consultas.php?cpf={cpf}&token={api_token}"

            print(f"🔍 Consultando API: {api_url}")

            # Adicionar timeout e headers
            req = urllib.request.Request(api_url)
            req.add_header('User-Agent', 'Mozilla/5.0')

            with urllib.request.urlopen(req, timeout=30) as response:
                data = response.read()
                print(f"✅ Resposta recebida: {len(data)} bytes")

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(data)

        except HTTPError as e:
            print(f"❌ HTTPError: {e.code} - {e.reason}")
            self.send_error(e.code, str(e))
        except Exception as e:
            print(f"❌ Erro ao consultar API: {type(e).__name__} - {e}")
            import traceback
            traceback.print_exc()
            self.send_error(500, "Erro ao consultar API")
    
    def handle_cpf_api_with_cpf(self, cpf):
        """Proxy para API de CPF (via POST)"""
        try:
            # Fazer requisição para API real
            api_token = "e3bd2312d93dca38d2003095196a09c2"
            api_url = f"https://apidecpf.site/api-v1/consultas.php?cpf={cpf}&token={api_token}"
            
            with urllib.request.urlopen(api_url) as response:
                data = response.read()
                
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(data)
            
        except HTTPError as e:
            self.send_error(e.code, str(e))
        except Exception as e:
            print(f"Erro ao consultar API: {e}")
            self.send_error(500, "Erro ao consultar API")
    
    def handle_mock_farmacias(self):
        """Mock para API de farmácias (não implementada)"""
        # Estrutura corrigida para corresponder ao que o código espera
        mock_data = {
            "success": True,
            "data": {
                "pharmacies": [],
                "location": {
                    "city": "São Paulo",
                    "region": "SP"
                }
            }
        }
        
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(mock_data).encode())
    
    def handle_mock_geo(self):
        """Mock para API de geolocalização (não implementada)"""
        mock_data = {
            "city": "São Paulo",
            "region": "SP",
            "regionName": "São Paulo",
            "country": "BR",
            "lat": -23.5505,
            "lon": -46.6333
        }
        
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(mock_data).encode())
    
    def handle_buscar_servicos_saude(self):
        """Mock para API de busca de serviços de saúde por CEP"""
        # Extrair CEP da URL
        cep = self.path.split('/')[-1]
        
        print(f"🏥 Buscando serviços de saúde para CEP: {cep}")
        
        # Mock de estabelecimentos de saúde
        mock_data = {
            "success": True,
            "cep": cep,
            "data": {
                "estabelecimentos": [
                    {
                        "name": "UBS Centro - Barra Funda",
                        "nome": "UBS Centro - Barra Funda",
                        "tipo": "Unidade Básica de Saúde",
                        "endereco": "Rua das Flores, 123",
                        "vicinity": "Rua das Flores, 123 - Centro",
                        "bairro": "Centro",
                        "cidade": "São Paulo",
                        "estado": "SP",
                        "telefone": "(11) 3333-4444",
                        "horario": "Segunda a Sexta: 7h às 17h",
                        "distancia": "1.2 km"
                    },
                    {
                        "name": "UBS Vila Mariana",
                        "nome": "UBS Vila Mariana",
                        "tipo": "Unidade Básica de Saúde",
                        "endereco": "Av. Paulista, 1000",
                        "vicinity": "Av. Paulista, 1000 - Vila Mariana",
                        "bairro": "Vila Mariana",
                        "cidade": "São Paulo",
                        "estado": "SP",
                        "telefone": "(11) 3344-5566",
                        "horario": "Segunda a Sexta: 8h às 18h",
                        "distancia": "2.5 km"
                    },
                    {
                        "name": "Hospital Municipal Dr. Fernando Mauro",
                        "nome": "Hospital Municipal Dr. Fernando Mauro",
                        "tipo": "Hospital",
                        "endereco": "Rua da Saúde, 500",
                        "vicinity": "Rua da Saúde, 500 - Centro",
                        "bairro": "Centro",
                        "cidade": "São Paulo",
                        "estado": "SP",
                        "telefone": "(11) 3555-6677",
                        "horario": "24 horas",
                        "distancia": "3.0 km"
                    }
                ]
            }
        }
        
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(mock_data).encode())
    
    def handle_calcular_preco(self):
        """Endpoint para calcular preço baseado no questionário de saúde"""
        try:
            # Ler dados do questionário
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            questionario_data = json.loads(post_data.decode('utf-8'))

            print(f"📊 Calculando preço para dados: {questionario_data}")

            # Lógica de cálculo de preço baseada nas respostas
            preco_base = 197.90  # Preço padrão
            dosagem_recomendada = "5mg"
            razao_recomendacao = "Dose inicial padrão recomendada"
            proxima_avaliacao = "4 semanas"

            # Ajustar preço e dosagem baseado nas respostas do questionário
            peso = questionario_data.get('peso', '')

            if peso == 'mais100':
                preco_base = 247.90
                dosagem_recomendada = "7.5mg"
                razao_recomendacao = "Dose ajustada para peso acima de 100kg"
                proxima_avaliacao = "6 semanas"
            elif peso == 'menos60':
                preco_base = 147.90
                dosagem_recomendada = "2.5mg"
                razao_recomendacao = "Dose inicial reduzida para peso abaixo de 60kg"
                proxima_avaliacao = "3 semanas"

            # Retornar resposta
            response_data = {
                "success": True,
                "data": {
                    "preco_base": preco_base,
                    "dosagemRecomendada": dosagem_recomendada,
                    "razaoRecomendacao": razao_recomendacao,
                    "proximaAvaliacao": proxima_avaliacao
                }
            }

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response_data).encode())

            print(f"✅ Preço calculado: R$ {preco_base} - Dosagem: {dosagem_recomendada}")

        except Exception as e:
            print(f"❌ Erro ao calcular preço: {e}")
            error_response = {
                "success": False,
                "error": str(e),
                "data": {
                    "preco_base": 197.90,
                    "dosagemRecomendada": "5mg",
                    "razaoRecomendacao": "Dose padrão devido a erro no processamento",
                    "proximaAvaliacao": "4 semanas"
                }
            }
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(error_response).encode())

    def handle_check_payment_status(self):
        """Verificação de status de pagamento PIX via KorePay"""
        try:
            # Extrair transaction_id da URL
            transaction_id = self.path.split('/')[-1]
            print(f"🔍 [KOREPAY] Verificando status do pagamento: {transaction_id}")
            
            # Se for transação simulada, retornar status pending sempre
            if transaction_id.startswith('MOCK_'):
                print(f"🧪 [MOCK] Verificando status de transação simulada")
                mock_status = {
                    "success": True,
                    "transaction_id": transaction_id,
                    "status": "pending",
                    "amount": 0,
                    "pix_code": "",
                    "timestamp": "",
                    "paid": False,
                    "message": "Aguardando pagamento (modo simulação)",
                    "simulation_mode": True
                }
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(mock_status).encode())
                return

            # Fazer requisição para API KorePay
            api_url = f"https://api.korepay.com.br/functions/v1/transactions/{transaction_id}"

            # Preparar requisição com autenticação HTTP Basic Auth
            auth_header = create_basic_auth_header(KOREPAY_SECRET_KEY)
            
            req = urllib.request.Request(
                api_url,
                headers={
                    'Accept': 'application/json',
                    'Authorization': auth_header,
                    'X-Project-Id': KOREPAY_RANDOM_KEY
                },
                method='GET'
            )
            
            print(f"🔑 [AUTH] Usando HTTP Basic Auth")
            print(f"🔑 [AUTH] API Key: {KOREPAY_SECRET_KEY[:20]}...")
            print(f"🔑 [AUTH] Project ID: {KOREPAY_RANDOM_KEY}")

            # Enviar requisição
            with urllib.request.urlopen(req, timeout=30) as response:
                response_data = response.read()
                korepay_response = json.loads(response_data.decode('utf-8'))

                print(f"✅ [KOREPAY] Resposta recebida: {len(response_data)} bytes")

            # Mapear status da KorePay para nosso formato
            # KorePay pode usar: pending, paid, expired, cancelled
            korepay_status = korepay_response.get('status', 'pending').lower()

            # Mapear para formato padrão
            # KorePay usa: waiting_payment, paid, expired, cancelled
            status_map = {
                'waiting_payment': 'pending',
                'pending': 'pending',
                'paid': 'completed',
                'expired': 'failed',
                'cancelled': 'failed',
                'completed': 'completed'
            }

            mapped_status = status_map.get(korepay_status, 'pending')

            # Extrair dados do pagamento
            amount = korepay_response.get('amount', 0) / 100  # Converter centavos para reais
            
            # Campo correto é 'qrcode' (minúsculo) dentro de 'pix'
            pix_data = korepay_response.get('pix', {})
            pix_code = pix_data.get('qrcode', '')  # ✅ Campo correto
            
            print(f"📋 [STATUS] Status KorePay: {korepay_status} → Mapeado: {mapped_status}")
            print(f"📋 [STATUS] Amount: R$ {amount}")
            print(f"📋 [STATUS] PIX code: {pix_code[:50] if pix_code else 'N/A'}...")

            # Formatar resposta padronizada
            response_data = {
                "success": True,
                "transaction_id": transaction_id,
                "status": mapped_status,
                "amount": amount,
                "pix_code": pix_code,
                "timestamp": korepay_response.get('createdAt', korepay_response.get('created_at', '')),
                "paid": mapped_status == 'completed',
                "message": "Pagamento concluído" if mapped_status == 'completed' else "Aguardando pagamento",
                "korepay_raw": korepay_response  # Incluir resposta completa para debug
            }

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response_data).encode())

            print(f"✅ [KOREPAY] Status: {mapped_status} (KorePay: {korepay_status})")

        except HTTPError as e:
            print(f"❌ [KOREPAY] HTTPError: {e.code} - {e.reason}")

            # Se for 404, a transação não existe
            if e.code == 404:
                error_response = {
                    "success": False,
                    "error": "Transação não encontrada",
                    "message": "ID de transação inválido ou expirado"
                }
                self.send_response(404)
            else:
                error_response = {
                    "success": False,
                    "error": str(e),
                    "message": "Erro ao verificar status do pagamento"
                }
                self.send_response(e.code)

            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(error_response).encode())

        except Exception as e:
            print(f"❌ [KOREPAY] Erro inesperado: {type(e).__name__} - {e}")
            import traceback
            traceback.print_exc()

            error_response = {
                "success": False,
                "error": str(e),
                "message": "Erro ao verificar status do pagamento"
            }
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(error_response).encode())

    def generate_mock_pix(self, payment_data):
        """Gera um PIX simulado para desenvolvimento"""
        import hashlib
        import base64
        from datetime import datetime, timedelta
        
        # Gerar transaction_id único baseado nos dados
        transaction_str = f"{payment_data.get('cpf', '')}{payment_data.get('amount', 0)}{datetime.now().isoformat()}"
        transaction_id = f"MOCK_{hashlib.md5(transaction_str.encode()).hexdigest()[:16]}"
        
        # Gerar código PIX válido (formato EMV)
        amount_str = f"{float(payment_data.get('amount', 197.90)):.2f}"
        pix_code = f"00020126580014br.gov.bcb.pix0136mock-gateway-dev-{transaction_id}520400005303986540{len(amount_str)}{amount_str}5802BR5925Programa Monjaro Mock6009SAO PAULO62070503***6304XXXX"
        
        # Gerar QR Code usando API externa (quickchart.io)
        # Isso gera um QR Code visual real que pode ser escaneado
        import urllib.parse
        qr_data = urllib.parse.quote(pix_code)
        pix_qrcode = f"https://quickchart.io/qr?text={qr_data}&size=300&margin=2"
        
        # Calcular expiração (24 horas)
        expires_at = (datetime.now() + timedelta(days=1)).isoformat()
        
        print(f"🧪 [MOCK] PIX simulado gerado: {transaction_id}")
        print(f"🧪 [MOCK] Código PIX: {pix_code[:50]}...")
        print(f"⚠️ [MOCK] ATENÇÃO: Este é um PIX de teste! Configure credenciais reais para produção.")
        
        return {
            "success": True,
            "transaction_id": transaction_id,
            "pix_code": pix_code,
            "pix_qrcode": pix_qrcode,
            "amount": float(payment_data.get('amount', 197.90)),
            "status": "pending",
            "expires_at": expires_at,
            "message": "⚠️ PIX SIMULADO (modo desenvolvimento) - Configure credenciais reais para produção",
            "simulation_mode": True
        }

    def handle_processar_pagamento(self):
        """Endpoint para processar pagamento Monjaro e gerar PIX via KorePay"""
        try:
            # Ler dados do pagamento
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            payment_data = json.loads(post_data.decode('utf-8'))

            print(f"💳 [KOREPAY] Processando pagamento para: {payment_data.get('name', 'N/A')}")
            print(f"💰 [KOREPAY] Valor: R$ {payment_data.get('amount', 0)}")

            # Extrair dados do cliente
            customer_name = payment_data.get('name', '')
            customer_email = payment_data.get('email', 'contato@monjaro.com.br')
            customer_phone = payment_data.get('phone', '11999999999').replace('(', '').replace(')', '').replace('-', '').replace(' ', '')
            customer_cpf = payment_data.get('cpf', '').replace('.', '').replace('-', '')

            # Calcular valor em centavos
            amount_reais = float(payment_data.get('amount', 197.90))
            amount_cents = int(amount_reais * 100)

            # Obter dosagem
            dosage = payment_data.get('dosage', '5mg')

            # Preparar payload para KorePay
            korepay_payload = {
                "customer": {
                    "name": customer_name,
                    "email": customer_email,
                    "phone": customer_phone,
                    "document": {
                        "number": customer_cpf,
                        "type": "CPF"
                    }
                },
                "paymentMethod": "PIX",
                "amount": amount_cents,
                "items": [
                    {
                        "title": f"Monjaro {dosage}",
                        "unitPrice": amount_cents,
                        "quantity": 1
                    }
                ],
                "pix": {
                    "expiresInDays": 1
                }
            }

            print(f"📤 [KOREPAY] Enviando requisição para API...")
            print(f"📦 [KOREPAY] Payload: {json.dumps(korepay_payload, indent=2)}")

            # Fazer requisição para API KorePay
            api_url = "https://api.korepay.com.br/functions/v1/transactions"

            # Preparar requisição com autenticação HTTP Basic Auth
            auth_header = create_basic_auth_header(KOREPAY_SECRET_KEY)
            
            req = urllib.request.Request(
                api_url,
                data=json.dumps(korepay_payload).encode('utf-8'),
                headers={
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'Authorization': auth_header,
                    'X-Project-Id': KOREPAY_RANDOM_KEY
                },
                method='POST'
            )
            
            print(f"🔑 [AUTH] Usando HTTP Basic Auth")
            print(f"🔑 [AUTH] API Key: {KOREPAY_SECRET_KEY[:20]}...")
            print(f"🔑 [AUTH] Project ID: {KOREPAY_RANDOM_KEY}")

            # Enviar requisição
            with urllib.request.urlopen(req, timeout=30) as response:
                response_data = response.read()
                korepay_response = json.loads(response_data.decode('utf-8'))

                print(f"✅ [KOREPAY] Resposta recebida: {len(response_data)} bytes")
                print(f"📋 [KOREPAY] Status: {response.status}")

            # Processar resposta da KorePay
            # Estrutura real da resposta: {"id": "...", "pix": {"qrcode": "...", "expirationDate": "..."}}
            transaction_id = korepay_response.get('id', 'unknown')
            
            # O campo correto é 'qrcode' (minúsculo) dentro de 'pix'
            pix_data = korepay_response.get('pix', {})
            pix_code = pix_data.get('qrcode', '')  # ✅ Campo correto da API KorePay
            expires_at = pix_data.get('expirationDate', korepay_response.get('createdAt', ''))
            
            # Gerar imagem do QR Code a partir do código PIX
            # Usando API externa gratuita (quickchart.io)
            if pix_code:
                pix_qrcode_url = f"https://quickchart.io/qr?text={urllib.parse.quote(pix_code)}&size=300&margin=2"
            else:
                pix_qrcode_url = ""
            
            print(f"✅ [KOREPAY] PIX gerado com sucesso: {transaction_id}")
            print(f"📋 [KOREPAY] Código PIX: {pix_code[:50] if pix_code else 'ERRO: Código vazio'}...")
            print(f"📋 [KOREPAY] QR Code URL: {pix_qrcode_url}")
            print(f"📋 [KOREPAY] Expira em: {expires_at}")

            # Formatar resposta padronizada para o frontend
            response_data = {
                "success": True,
                "transaction_id": transaction_id,
                "pix_code": pix_code,
                "pix_qrcode": pix_qrcode_url,
                "amount": amount_reais,
                "status": "pending",
                "expires_at": expires_at,
                "message": "PIX gerado com sucesso via KorePay",
                "korepay_raw": korepay_response  # Incluir resposta completa para debug
            }

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response_data).encode())

        except HTTPError as e:
            print(f"❌ [KOREPAY] HTTPError: {e.code} - {e.reason}")
            # Ler corpo da resposta de erro
            try:
                error_body = e.read().decode('utf-8')
                print(f"📋 [KOREPAY] Erro detalhado: {error_body}")
                error_data = json.loads(error_body)
            except:
                error_data = {"message": str(e)}

            # Se modo de simulação estiver ativo e erro for 401, usar PIX mock
            if KOREPAY_SIMULATION_MODE and e.code == 401:
                print(f"🧪 [MOCK] Credenciais KorePay inválidas. Usando PIX simulado...")
                mock_response = self.generate_mock_pix(payment_data)
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(mock_response).encode())
                return

            error_response = {
                "success": False,
                "error": error_data.get('message', str(e)),
                "error_code": e.code,
                "message": "Erro ao processar pagamento com KorePay"
            }
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(error_response).encode())

        except Exception as e:
            print(f"❌ [KOREPAY] Erro inesperado: {type(e).__name__} - {e}")
            import traceback
            traceback.print_exc()

            error_response = {
                "success": False,
                "error": str(e),
                "message": "Erro interno ao processar pagamento"
            }
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(error_response).encode())

def run(port=8000):
    server_address = ('', port)
    httpd = HTTPServer(server_address, CORSRequestHandler)
    print(f"🚀 Servidor iniciado em http://localhost:{port}/")
    print(f"📡 Proxy de API de CPF ativo")
    print(f"🔒 CORS habilitado")
    print(f"\nPressione Ctrl+C para parar\n")
    httpd.serve_forever()

if __name__ == '__main__':
    run(8000)
