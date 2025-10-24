# Análise Completa - Bugs de Valores em pagamento_pix/index.html

## Bugs Identificados

### 🐛 BUG #1: Valores Hardcoded no HTML

**Localização:** Linhas 1183 e 1192

**Problema:**
```html
<span id="medicationAmount">R$&nbsp;105,15</span>
<!-- ... -->
<span id="totalAmount">R$&nbsp;105,15</span>
```

**Impacto:**
- Valores não mudam dinamicamente
- Não refletem a dosagem selecionada
- Confundem o usuário

**Solução:** Substituir por valores dinâmicos ou placeholder.

---

### 🐛 BUG #2: Múltiplas Fontes de Dados Conflitantes

**Fontes identificadas:**

1. **`pixData.amount`** (linha 1392, 1698, 1708)
   - Vem do localStorage `pix_data`
   - Salvo quando PIX é gerado em `/solicitacao`
   - Pode estar desatualizado se dosagem mudou

2. **`localStorage.calculatedPrice`** (linha 2083)
   - Vem da página `/selecao`
   - Atualizado quando usuário seleciona dosagem
   - **FONTE CORRETA** ✅

**Conflito:**
```javascript
// initializePageData() usa pixData.amount
document.getElementById('totalAmount').textContent = `R$ ${parseFloat(amount).toFixed(2)}`;

// updatePriceFromCompra() usa calculatedPrice
totalAmountElement.textContent = formatPrice(medicationPrice);
```

**Problema:** Qual valor prevalece depende da ordem de execução!

---

### 🐛 BUG #3: Múltiplas Funções Atualizando Mesmos Elementos

**Funções que atualizam `totalAmount`:**

1. **`initializePageData()`** - linha 1418-1420
   ```javascript
   if (amount) {
     document.getElementById('totalAmount').textContent = `R$ ${parseFloat(amount).toFixed(2).replace('.', ',')}`;  
   }
   ```

2. **`loadShippingInfo()`** - linha 1694-1720
   ```javascript
   const totalAmount = basePrice + shippingCost;
   totalAmountEl.textContent = `R$ ${totalAmount.toFixed(2).replace('.', ',')}`;
   ```

3. **`updatePriceFromCompra()`** - linha 2114-2116
   ```javascript
   if (totalAmountElement) {
     totalAmountElement.textContent = formatPrice(totalPrice);
   }
   ```

**Problema:** 
- Três funções sobrescrevendo o mesmo elemento
- Não há garantia de ordem de execução
- Pode causar valores incorretos ou inconsistentes

---

### 🐛 BUG #4: Cálculo de Frete Duplicado e Inconsistente

**Duas implementações diferentes:**

1. **Em `loadShippingInfo()`** (linha 1699-1705):
   ```javascript
   let shippingCost = 0;
   if (shippingOption === 'express') {
     shippingCost = 26.44;  // ❌ Valor diferente!
   } else if (shippingOption === 'pharmacy') {
     shippingCost = 26.44;  // ❌ Valor diferente!
   }
   ```

2. **Em `calculateShippingCost()`** (linha 2064-2077):
   ```javascript
   case 'express':
     return 14.28;  // ✅ Valor correto
   case 'pharmacy':
     return 28.14;  // ✅ Valor correto
   ```

**Problema:** Valores de frete inconsistentes entre funções!

---

### 🐛 BUG #5: Ordem de Execução Imprevisível

**Ordem atual:**
```javascript
window.addEventListener('load', function() {
  initializePageData();           // 1. Usa pixData.amount
  updateDeliveryDates();          // 2. Não afeta valores
  personalizePaymentGuide();      // 3. Chama updatePriceFromCompra()
  personalizeWhatsAppNotifications(); // 4. Não afeta valores
});
```

**Dentro de `initializePageData()`:**
```javascript
initializePageData() {
  // ... código ...
  loadShippingInfo();  // ← Também atualiza valores!
}
```

**Fluxo real:**
```
1. initializePageData()
   → Define totalAmount = pixData.amount (ERRADO)
2. loadShippingInfo()
   → Recalcula totalAmount = basePrice + shippingCost (usando pixData.amount ainda)
3. personalizePaymentGuide()
   → updatePriceFromCompra()
   → Define totalAmount = calculatedPrice + shippingCost (CORRETO)
```

**Problema:** O valor correto só aparece no final, mas pode haver "flash" de valores errados.

---

### 🐛 BUG #6: Falta de Sincronização com Tabela de Preços

Na página `/selecao`, implementamos:
```javascript
const TABELA_PRECOS = {
  '2.5mg': 147.90,
  '5mg': 197.90,
  '7.5mg': 247.90,
  '10mg': 297.90,
  '15mg': 347.90
};
```

Mas em `/pagamento_pix`, **não há validação** se o valor está correto!

**Problema:** Não garante consistência entre páginas.

---

### 🐛 BUG #7: Elementos `medicationAmount` e `shippingAmount` Não Atualizados Consistentemente

**HTML tem elementos separados:**
```html
<span id="medicationAmount">R$&nbsp;105,15</span>
<span id="shippingAmount">...</span>
<span id="totalAmount">R$&nbsp;105,15</span>
```

**Apenas `updatePriceFromCompra()` atualiza todos:**
- ✅ `medicationAmount`
- ✅ `shippingAmount`  
- ✅ `totalAmount`

**Outras funções atualizam apenas `totalAmount`:**
- ❌ `initializePageData()`
- ❌ `loadShippingInfo()`

**Problema:** Valores parciais podem ficar desatualizados.

---

## Resumo dos Bugs

| # | Bug | Severidade | Impacto |
|---|-----|------------|---------|
| 1 | Valores hardcoded | 🟡 Média | Valores iniciais errados |
| 2 | Fontes de dados conflitantes | 🔴 Alta | Valores incorretos |
| 3 | Múltiplas funções sobrescrevendo | 🔴 Alta | Inconsistência |
| 4 | Frete com valores diferentes | 🔴 Alta | Cálculo errado |
| 5 | Ordem de execução imprevisível | 🟡 Média | Flash de valores errados |
| 6 | Sem validação com tabela de preços | 🟡 Média | Inconsistência entre páginas |
| 7 | Elementos parciais desatualizados | 🟡 Média | Interface inconsistente |

---

## Solução Proposta

### 1. **Fonte Única de Verdade**
- Usar **APENAS** `localStorage.calculatedPrice` como fonte de dados
- Ignorar `pixData.amount` (pode estar desatualizado)
- Validar com tabela de preços da página `/selecao`

### 2. **Função Única de Atualização**
- Consolidar em **uma única função**: `atualizarTodosOsValores()`
- Remove funções duplicadas
- Garante consistência

### 3. **Valores de Frete Unificados**
- Usar APENAS `calculateShippingCost()`
- Remover implementação duplicada

### 4. **Ordem de Execução Garantida**
```javascript
window.addEventListener('load', function() {
  carregarDadosPix();           // 1. Carregar PIX code e QR code
  atualizarTodosOsValores();    // 2. Atualizar valores (fonte única)
  configurarEventos();          // 3. Configurar botões
  iniciarPolling();             // 4. Iniciar verificação de status
});
```

### 5. **HTML com Placeholders**
```html
<span id="medicationAmount">Carregando...</span>
<span id="totalAmount">Carregando...</span>
```

### 6. **Validação com Tabela de Preços**
```javascript
const TABELA_PRECOS = {
  '2.5mg': 147.90,
  '5mg': 197.90,
  '7.5mg': 247.90,
  '10mg': 297.90,
  '15mg': 347.90
};

function validarPreco(dosagem, preco) {
  const precoEsperado = TABELA_PRECOS[dosagem];
  if (precoEsperado && Math.abs(preco - precoEsperado) > 0.01) {
    console.warn(`[VALIDAÇÃO] Preço inconsistente! Esperado: ${precoEsperado}, Recebido: ${preco}`);
    return precoEsperado; // Corrigir automaticamente
  }
  return preco;
}
```

---

## Próximos Passos

1. ✅ Documentar bugs (este arquivo)
2. ⏳ Implementar correções
3. ⏳ Testar fluxo completo
4. ⏳ Validar com diferentes dosagens
5. ⏳ Testar com diferentes opções de frete
