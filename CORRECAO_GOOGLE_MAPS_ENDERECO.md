# Correção - Erro Google Maps na Página de Endereço

## Problema Identificado

**Erro no Console:**
```
Uncaught TypeError: Cannot read properties of undefined (reading 'mJ')
    at Object.QI (common.js:103:245)
```

**Causa Raiz:**
O erro ocorria porque `common.js` e `util.js` (módulos do Google Maps) estavam sendo carregados **ANTES** da API do Google Maps estar completamente inicializada.

### Sequência Problemática:
1. Browser começa a carregar `google/maps/api/js` (com `async defer`)
2. Browser carrega imediatamente `common.js` (estático no `<head>`)
3. `common.js` tenta executar código que requer `google.maps.__gjsload__`
4. ❌ ERRO: `google` ainda não existe

## Solução Aplicada

### Arquivo Modificado:
- **endereco/index.html** (3584 linhas → 3612 linhas)

### Mudanças Implementadas:

#### 1. Adicionada Callback Function (linhas 13-17)
```javascript
function initGoogleMaps() {
  console.log('[MAPS] Google Maps API carregado com sucesso');
  window.dispatchEvent(new Event('google-maps-loaded'));
}
```

#### 2. URL do Maps API com Callback (linha 19)
**Antes:**
```html
<script src="https://maps.googleapis.com/maps/api/js?key=...&loading=async" async defer></script>
```

**Depois:**
```html
<script src="https://maps.googleapis.com/maps/api/js?key=...&loading=async&callback=initGoogleMaps" async defer></script>
```

#### 3. Carregamento Estático Removido (antes linha 2363)
**Removido:**
```html
<script type="text/javascript" charset="UTF-8" src="./index_files/common.js"></script>
<script type="text/javascript" charset="UTF-8" src="./index_files/util.js"></script>
```

#### 4. Carregamento Dinâmico Adicionado (linhas 2365-2388)
```javascript
function loadGoogleMapsModules() {
  if (typeof google !== 'undefined' && google.maps) {
    const commonScript = document.createElement('script');
    commonScript.src = './index_files/common.js';
    commonScript.charset = 'UTF-8';
    document.head.appendChild(commonScript);
    
    const utilScript = document.createElement('script');
    utilScript.src = './index_files/util.js';
    utilScript.charset = 'UTF-8';
    document.head.appendChild(utilScript);
    
    console.log('[MAPS] Módulos common.js e util.js carregados');
  } else {
    setTimeout(loadGoogleMapsModules, 100);
  }
}

window.addEventListener('google-maps-loaded', loadGoogleMapsModules);
setTimeout(loadGoogleMapsModules, 2000); // Fallback timeout
```

## Como Funciona Agora

### Sequência Corrigida:
1. ✅ Browser carrega `google/maps/api/js` com `async defer`
2. ✅ Quando Maps API termina de carregar → `initGoogleMaps()` é chamada
3. ✅ Callback dispara evento `'google-maps-loaded'`
4. ✅ Event listener detecta e chama `loadGoogleMapsModules()`
5. ✅ Função verifica que `google.maps` existe
6. ✅ **AGORA SIM** carrega `common.js` e `util.js` dinamicamente
7. ✅ Módulos executam sem erros

### Proteções Implementadas:

1. **Event Listener**: Aguarda o evento personalizado
2. **Polling**: Verifica `google.maps` a cada 100ms se ainda não existe
3. **Fallback Timeout**: Tenta carregar após 2 segundos mesmo sem evento

## Logs de Console Esperados

Após a correção, você deve ver:
```
[MAPS] Google Maps API carregado com sucesso
[MAPS] Módulos common.js e util.js carregados
```

## Verificação

### Teste Manual:
1. Acesse `http://localhost:8000/endereco`
2. Abra DevTools (F12) → Console
3. Verifique:
   - ✅ Sem erros `Cannot read properties of undefined`
   - ✅ Logs `[MAPS] ...` aparecem
   - ✅ Mapa do Google funciona normalmente

### Teste de Código:
```javascript
// No console do browser, após carregar a página:
console.log(typeof google); // Deve retornar: "object"
console.log(typeof google.maps); // Deve retornar: "object"
```

## Impacto

**Páginas Afetadas:** endereco/index.html
**Status:** ✅ Corrigido
**Servidor Reiniciado:** Sim

## Notas Técnicas

- O erro `reading 'mJ'` era uma propriedade minificada dentro de `common.js`
- `common.js` e `util.js` são módulos internos do Google Maps (não código nosso)
- A propriedade específica varia com a versão da API (pode ser `mJ`, `nK`, etc.)
- A solução é padrão Google Maps: sempre usar callback quando carregar `async`

## Referências

- Google Maps JavaScript API: Loading Strategy
- Similar issue in selecao/index.html (previously fixed)
- Pattern: Callback-based loading ensures proper initialization order
