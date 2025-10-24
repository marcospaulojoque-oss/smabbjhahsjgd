# 🐛 ANÁLISE COMPLETA: Bugs na Página de Seleção de Dosagem

## ❌ PROBLEMAS CRÍTICOS IDENTIFICADOS

---

## 🔴 **BUG #1: Múltiplas Funções Conflitantes**

### **Problema:**
Existem **DUAS funções diferentes** fazendo a mesma coisa:

**Função 1** (linha 1457):
```javascript
async function calcularPrecoEDosagem() {
  // Calcula dosagem baseado no peso do questionário
  // Lógica local simplificada
}
```

**Função 2** (linha 3566):
```javascript
async function calcularPrecoEDosagemViaAPI() {
  // Chama endpoint /api/calcular-preco
  // Retorna dosagem calculada pelo backend
}
```

### **Impacto:**
- As duas funções são chamadas em momentos diferentes
- Cada uma define uma dosagem recomendada diferente
- Causa inconsistência na UI

### **Onde são chamadas:**
- `calcularPrecoEDosagem()` → linha 2037 (dentro de `updatePrices()`)
- `calcularPrecoEDosagemViaAPI()` → linha 3965 (no `DOMContentLoaded`)

---

## 🔴 **BUG #2: Sobrescrita Confusa de Função**

### **Problema (linha 2414-2422):**
```javascript
// Sobrescreve a função original
const calcularPrecoEDosagemOriginal = calcularPrecoEDosagem;
calcularPrecoEDosagem = async function() {
  const resultado = await calcularPrecoEDosagemOriginal();
  definirDosagemRecomendada(resultado.dosagem);  // ← Adiciona comportamento
  return resultado;
};
```

### **Impacto:**
- Modifica comportamento da função original
- Adiciona layer extra de complexidade
- Dificulta debug e manutenção
- Pode causar loops infinitos se mal configurado

---

## 🔴 **BUG #3: Seleção Manual Sendo Sobrescrita**

### **Problema Principal:**

**Usuário seleciona manualmente** (linha 2377-2404):
```javascript
opcoesDosagem.forEach(opcao => {
  opcao.addEventListener('change', function() {
    selecaoManualFeita = true;  // ← Marca que foi manual
    const dosagemSelecionada = this.value;
    localStorage.setItem('selected_dosage', dosagemSelecionada);  // ← Salva escolha
    console.log(`Nova dosagem selecionada: ${dosagemSelecionada}`);
  });
});
```

**MAS... a função `marcarDosagemRecomendada()` SOBRESCREVE** (linha 2714-2730):
```javascript
function marcarDosagemRecomendada(dosagem) {
  const dosageOption = document.querySelector(`input[value="${dosagem}"]`);
  if (dosageOption) {
    dosageOption.checked = true;  // ← Força seleção
    dosageOption.closest('.dosage-option').classList.add('recommended');
  }
  
  // 🔴 PROBLEMA: SEMPRE sobrescreve a seleção do usuário!
  localStorage.setItem('selected_dosage', dosagem);  // ← linha 2725
}
```

### **Fluxo do Bug:**
1. Usuário seleciona **10mg** manualmente → salvo no localStorage
2. Página carrega `calcularPrecoEDosagemViaAPI()`
3. API calcula dosagem recomendada: **7.5mg**
4. Chama `marcarDosagemRecomendada('7.5mg')`
5. **SOBRESCREVE** a escolha do usuário! ❌

### **Impacto:**
- Seleção manual do usuário é perdida
- Variável `selecaoManualFeita` não é respeitada
- Usuário fica confuso pois sua escolha desaparece

---

## 🔴 **BUG #4: Duplicação de Seleção Automática**

### **Problema:**

**Seleção Automática #1** (linha 2692-2698):
```javascript
const dosageInicial = document.querySelector('input[value="2.5mg"]');
if (dosageInicial && !localStorage.getItem('selected_dosage')) {
  dosageInicial.checked = true;
  localStorage.setItem('selected_dosage', '2.5mg');
}
```

**Seleção Automática #2** (linha 2719-2725):
```javascript
function marcarDosagemRecomendada(dosagem) {
  dosageOption.checked = true;
  localStorage.setItem('selected_dosage', dosagem);  // ← Sobrescreve #1!
}
```

### **Impacto:**
- Primeiro seleciona 2.5mg
- Depois imediatamente sobrescreve com dosagem recomendada
- Execução desnecessária

---

## 🔴 **BUG #5: Ordem de Execução Errada**

### **Problema:**

**Ordem atual** (linha 2430-2441):
```javascript
document.addEventListener('DOMContentLoaded', async function() {
  // 1. Aplica personalização
  applyPersonalization();
  
  // 2. Configura seletores
  configurarSeletorDosagem();
  
  // 3. Calcula preços E dosagem
  await updatePrices();  // ← Chama calcularPrecoEDosagem()
  
  // ... depois lá embaixo (linha 3965):
  calcularPrecoEDosagemViaAPI();  // ← Chama OUTRA função de calcular dosagem!
});
```

### **Impacto:**
- Calcula dosagem DUAS vezes
- Resultados podem ser diferentes
- Última chamada sobrescreve a primeira
- Performance ruim (2x API calls)

---

## 🔴 **BUG #6: Variável `selecaoManualFeita` Não É Respeitada**

### **Problema:**

**Variável definida mas não usada** (linha 2338):
```javascript
let selecaoManualFeita = false;

// Quando usuário seleciona manualmente:
opcao.addEventListener('change', function() {
  selecaoManualFeita = true;  // ← Define como true
});

// MAS... nenhuma função verifica essa variável antes de sobrescrever!
function marcarDosagemRecomendada(dosagem) {
  // ❌ Não verifica if (selecaoManualFeita) antes de forçar seleção
  localStorage.setItem('selected_dosage', dosagem);
}
```

### **Impacto:**
- Flag existe mas é ignorada
- Não protege escolha manual do usuário

---

## 🔴 **BUG #7: Cálculo Local vs API Inconsistente**

### **Problema:**

**Cálculo local** (linha 1475-1484):
```javascript
if (questionnaireData.peso) {
  const peso = parseFloat(questionnaireData.peso);
  if (peso >= 100) {
    dosagem = '7.5mg';
  } else if (peso >= 85) {
    dosagem = '5mg';
  } else {
    dosagem = '2.5mg';
  }
}
```

**VS Cálculo da API** (backend em `proxy_api.py`):
```python
if peso == 'mais100':
    dosagem_recomendada = "7.5mg"
elif peso == 'menos60':
    dosagem_recomendada = "2.5mg"
```

### **Impacto:**
- Lógicas diferentes!
- Frontend usa valor numérico do peso
- Backend usa categoria ('mais100', 'menos60')
- Resultados podem divergir

---

## 📊 **RESUMO DOS BUGS:**

| # | Bug | Severidade | Impacto |
|---|-----|-----------|---------|
| 1 | Múltiplas funções conflitantes | 🔴 Alta | Inconsistência geral |
| 2 | Sobrescrita confusa de função | 🟡 Média | Dificulta manutenção |
| 3 | Seleção manual sobrescrita | 🔴 Alta | Perde escolha do usuário |
| 4 | Duplicação de seleção automática | 🟡 Média | Performance ruim |
| 5 | Ordem de execução errada | 🔴 Alta | Cálculos duplicados |
| 6 | Flag não respeitada | 🟡 Média | Código inútil |
| 7 | Lógica inconsistente | 🔴 Alta | Resultados diferentes |

---

## ✅ **SOLUÇÃO PROPOSTA:**

### **1. Remover duplicação - usar APENAS uma função:**
```javascript
// Manter APENAS calcularPrecoEDosagemViaAPI()
// Remover calcularPrecoEDosagem() local
```

### **2. Respeitar seleção manual:**
```javascript
function marcarDosagemRecomendada(dosagem) {
  // ✅ ADICIONAR VERIFICAÇÃO
  if (selecaoManualFeita) {
    console.log('[DOSAGEM] Seleção manual detectada, não sobrescrever');
    return;  // ← NÃO sobrescrever!
  }
  
  // Verificar se já existe seleção no localStorage
  const selecaoExistente = localStorage.getItem('selected_dosage');
  if (selecaoExistente) {
    console.log('[DOSAGEM] Já existe seleção, mantendo:', selecaoExistente);
    return;
  }
  
  // Só então marcar recomendada
  localStorage.setItem('selected_dosage', dosagem);
}
```

### **3. Simplificar ordem de execução:**
```javascript
document.addEventListener('DOMContentLoaded', async function() {
  // 1. Configurar seletores PRIMEIRO
  configurarSeletorDosagem();
  
  // 2. Calcular dosagem UMA VEZ
  const result = await calcularPrecoEDosagemViaAPI();
  
  // 3. SE não houver seleção manual, marcar recomendada
  if (!selecaoManualFeita && !localStorage.getItem('selected_dosage')) {
    marcarDosagemRecomendada(result.data.dosagemRecomendada);
  }
  
  // 4. Atualizar UI
  atualizarElementosVisuais();
});
```

### **4. Unificar lógica de cálculo:**
```javascript
// Usar APENAS o backend para calcular
// Remover lógica duplicada do frontend
```

---

## 🎯 **PRIORIDADE DE CORREÇÃO:**

### **Urgente (fazer AGORA):**
1. ✅ Corrigir Bug #3 - Respeitar seleção manual
2. ✅ Corrigir Bug #5 - Remover duplicação de chamadas
3. ✅ Corrigir Bug #1 - Usar apenas uma função

### **Importante (fazer depois):**
4. ✅ Corrigir Bug #7 - Unificar lógica de cálculo
5. ✅ Corrigir Bug #4 - Remover seleção automática duplicada

### **Melhorias (opcional):**
6. Limpar Bug #2 - Remover sobrescrita confusa
7. Limpar Bug #6 - Remover código não usado

---

## 🧪 **COMO TESTAR:**

### **Teste 1: Seleção Manual**
1. Abrir página `/selecao`
2. Selecionar **10mg** manualmente
3. Recarregar página (F5)
4. ✅ **Esperado**: Deve manter **10mg** selecionado
5. ❌ **Atual**: Volta para dosagem recomendada (7.5mg ou 5mg)

### **Teste 2: Dosagem Recomendada**
1. Limpar localStorage: `localStorage.clear()`
2. Fazer questionário com peso > 100kg
3. Chegar em `/selecao`
4. ✅ **Esperado**: Deve mostrar **7.5mg** recomendada
5. ❌ **Atual**: Mostra dosagens conflitantes ou troca

### **Teste 3: Persistência**
1. Selecionar **12.5mg**
2. Clicar em "Prosseguir"
3. Voltar para `/selecao`
4. ✅ **Esperado**: Deve manter **12.5mg**
5. ❌ **Atual**: Perde a seleção

---

## 📝 **CÓDIGO PARA DEBUG:**

Adicionar no console para verificar estado:

```javascript
// Ver estado atual
console.log('Dosagem no localStorage:', localStorage.getItem('selected_dosage'));
console.log('Seleção manual feita:', window.selecaoManualFeita);
console.log('Dosagem recomendada:', window.dosagemRecomendada);

// Ver qual input está selecionado
document.querySelectorAll('input[name="selectedDosage"]').forEach(input => {
  if (input.checked) {
    console.log('Input selecionado:', input.value);
  }
});
```

---

**Análise completa realizada em:** 2025-10-18  
**Total de bugs identificados:** 7  
**Severidade:** 3 Altos, 3 Médios, 1 Baixo

