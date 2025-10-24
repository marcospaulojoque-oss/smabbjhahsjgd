# RELATÓRIO DE ANÁLISE COMPLETA DO PROJETO MONJARO

**Data:** 2025
**Versão:** 1.0
**Escopo:** Análise técnica completa identificando bugs, incompatibilidades e problemas de implementação

---

## 📋 SUMÁRIO EXECUTIVO

Este relatório identifica **problemas críticos e oportunidades de melhoria** no projeto de distribuição do Monjaro. A análise revelou que dados valiosos da API de CPF **não estão sendo utilizados adequadamente** no fluxo da aplicação, além de outros problemas técnicos.

### Índice de Severidade
- 🔴 **CRÍTICO**: Funcionalidade quebrada ou dados não utilizados
- 🟡 **MÉDIO**: Problema que afeta experiência mas não bloqueia fluxo
- 🟢 **BAIXO**: Melhoria cosmética ou otimização

---

## 🔴 1. PROBLEMA CRÍTICO: DADOS DA API DE CPF NÃO UTILIZADOS

### Descrição do Problema
A API de CPF retorna dados ricos que **não estão sendo aproveitados** no projeto.

### Localização
- **Arquivo**: `/validar-dados/index.html`
- **Linhas**: Script JavaScript de consulta à API

### O que a API retorna
```javascript
{
  "Result": {
    "Nome": "NOME COMPLETO DO USUÁRIO",
    "DataNascimento": "01/01/1990",
    "Sexo": "MASCULINO",
    "Telefones": [
      {
        "telefone": "(11) 99999-9999",
        "operadora": "CLARO",
        "tipo": "Celular"
      }
    ],
    "Emails": [
      {
        "email": "usuario@email.com",
        "provedor": "gmail.com"
      }
    ],
    "Enderecos": [
      {
        "logradouro": "RUA EXEMPLO",
        "numero": "123",
        "bairro": "CENTRO",
        "cidade": "SÃO PAULO",
        "estado": "SP",
        "cep": "01234-567"
      }
    ],
    "NomeMae": "NOME DA MÃE",
    "NomePai": "NOME DO PAI",
    "Municipio": "SÃO PAULO",
    "UF": "SP"
  }
}
```

### O que está sendo salvo atualmente
**Apenas o nome completo:**
```javascript
localStorage.setItem('nomeCompleto', data.Result.Nome);
```

### O que deveria ser salvo
```javascript
// Salvar TODOS os dados da API
localStorage.setItem('cpfData', JSON.stringify(data));
```

### Impacto
- ❌ Usuário precisa **digitar manualmente** telefone, email e endereço
- ❌ Página `/endereco` tem código para autocompletar, mas **não funciona**
- ❌ Perda de experiência do usuário
- ❌ Dados pagos da API são **desperdiçados**

### Solução Recomendada
**Arquivo: `/validar-dados/index.html`**

Localizar o código onde salva o nome:
```javascript
localStorage.setItem("nomeCompleto", realData.fullName);
```

Adicionar logo após:
```javascript
// Salvar dados completos da API para uso nas próximas páginas
localStorage.setItem('cpfData', JSON.stringify(realData));

// Salvar também dados específicos que já estão estruturados
if (realData.birthDate) {
  localStorage.setItem('dataNascimento', realData.birthDate);
}
if (realData.sexo) {
  localStorage.setItem('sexo', realData.sexo);
}
```

---

## 🔴 2. AUTOCOMPLETAR DE TELEFONES E EMAILS NÃO FUNCIONA

### Descrição
A página de endereço (`/endereco`) tem código JavaScript **pronto** para autocompletar telefones e emails usando dados da API, mas **não funciona** porque os dados não foram salvos.

### Localização
- **Arquivo**: `/endereco/index.html`
- **Funções afetadas**:
  - `obterTelefonesDoCpfData()` (linha ~285)
  - `obterEmailsDoCpfData()` (linha ~522)

### Código existente que não funciona
```javascript
function obterTelefonesDoCpfData() {
  try {
    const cpfDataStr = localStorage.getItem("cpfData");
    if (!cpfDataStr) return [];  // ❌ Sempre retorna vazio

    const cpfData = JSON.parse(cpfDataStr);
    const telefones = cpfData?.Result?.Telefones || [];
    // ... código para processar telefones
  }
}
```

### Por que não funciona
O `localStorage.getItem("cpfData")` retorna `null` porque nunca foi salvo na página de validação.

### Evidência do problema
No próprio código há logs de debug:
```javascript
console.log(`[ENDERECO DEBUG] ${telefonesDisponiveis.length} telefones encontrados na base de dados governamental:`, telefonesDisponiveis);
```

Esse log sempre mostrará **0 telefones** porque os dados não existem.

### Solução
1. Implementar a correção do item #1 (salvar cpfData completo)
2. O código de autocompletar **já está pronto** e funcionará automaticamente

---

## 🟡 3. DADOS DE ENDEREÇO DA API NÃO SÃO PRÉ-PREENCHIDOS

### Descrição
A API retorna endereços do usuário, mas eles não são usados para pré-preencher o formulário.

### Oportunidade
Quando o usuário chegar na página `/endereco`:
1. Verificar se há endereços em `cpfData`
2. Pré-selecionar ou sugerir o endereço mais recente
3. Usuário pode confirmar ou editar

### Exemplo de implementação
```javascript
function preencherEnderecoSeDisponivel() {
  try {
    const cpfDataStr = localStorage.getItem("cpfData");
    if (!cpfDataStr) return;
    
    const cpfData = JSON.parse(cpfDataStr);
    const enderecos = cpfData?.Result?.Enderecos || [];
    
    if (enderecos.length > 0) {
      const enderecoPrincipal = enderecos[0];
      
      // Pré-preencher campos se estiverem vazios
      if (!document.getElementById('street').value) {
        document.getElementById('street').value = enderecoPrincipal.logradouro || '';
      }
      if (!document.getElementById('number').value) {
        document.getElementById('number').value = enderecoPrincipal.numero || '';
      }
      if (!document.getElementById('neighborhood').value) {
        document.getElementById('neighborhood').value = enderecoPrincipal.bairro || '';
      }
      if (!document.getElementById('city').value) {
        document.getElementById('city').value = enderecoPrincipal.cidade || '';
      }
      if (!document.getElementById('state').value) {
        document.getElementById('state').value = enderecoPrincipal.estado || '';
      }
      if (!document.getElementById('cep').value) {
        document.getElementById('cep').value = enderecoPrincipal.cep || '';
      }
    }
  } catch (error) {
    console.error('[ENDERECO] Erro ao pré-preencher endereço:', error);
  }
}
```

---

## 🟡 4. IMAGENS E ÍCONES COM PROBLEMAS

### 4.1. Fontes Rawline retornando 404

**Localização**: Todas as páginas HTML
```html
<link rel="stylesheet" href="./index_files/rawline-fonts.css">
```

**Problema**: O arquivo `rawline-fonts.css` referencia URLs de fontes que retornam 404:
```css
@font-face {
  font-family: "Rawline";
  src: url("/static/fonts/rawline-400.woff2") format("woff2");
}
```

**Impacto**: 🟢 BAIXO - As fontes fallback (Arial, sans-serif) funcionam corretamente

**Solução**: 
1. Remover referências a fontes inexistentes
2. Ou baixar as fontes e colocá-las nos diretórios corretos

### 4.2. Imagens duplicadas em múltiplos diretórios

**Problema**: As mesmas imagens existem em múltiplos diretórios:
```
./index_files/Gov.br_logo.svg.png
./cadastro/index_files/Gov.br_logo.svg.png
./endereco/index_files/Gov.br_logo.svg.png
./selecao/index_files/Gov.br_logo.svg.png
... (mais 7 cópias)
```

**Impacto**: 🟢 BAIXO - Desperdício de espaço, mas não afeta funcionalidade

**Solução recomendada**:
1. Criar diretório `/assets/images/` centralizado
2. Atualizar todas as referências
3. Remover duplicatas

### 4.3. Imagem de produto específica

**Localização**: `/selecao/index_files/2.5mg.jpg`

**Status**: ✅ Existe apenas para dosagem 2.5mg

**Problema potencial**: Se houver outras dosagens (5mg, 7.5mg, etc), faltam imagens

---

## 🟡 5. PROBLEMAS NA PÁGINA DE SOLICITAÇÃO

### 5.1. Função de cálculo de preço duplicada

**Localização**: `/solicitacao/index.html`

**Problema**: Existem duas funções para calcular preço:
1. `calcularPrecoEDosagemViaAPI()` - Faz chamada para `/api/calcular-preco`
2. `calcularPrecoEDosagem()` - Calcula localmente

**Risco**: Inconsistência entre cálculos local e servidor

**Solução**: Usar apenas a API, remover lógica duplicada

### 5.2. Endpoint `/api/calcular-preco` não implementado

**Código na página**:
```javascript
const response = await fetch('/api/calcular-preco', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(questionnaireData)
});
```

**Problema**: O `proxy_api.py` **não tem** rota para `/api/calcular-preco`

**Impacto**: 🔴 CRÍTICO - Cálculo de preço pode falhar

**Solução**: Adicionar rota no `proxy_api.py` ou garantir que fallback funcione

---

## 🟢 6. QUESTÕES MENORES

### 6.1. Console logs em produção

**Problema**: Muitos `console.log()` no código
```javascript
console.log("[ENDERECO DEBUG] ===== PÁGINA DE ENDEREÇO CARREGADA =====");
```

**Impacto**: 🟢 BAIXO - Poluição do console, mas útil para debug

**Solução**: Adicionar flag de desenvolvimento e remover logs em produção

### 6.2. Código comentado

**Exemplo em `/endereco/index.html`**:
```javascript
// let eMail = null;
// let nCompleto = null;
```

**Impacto**: 🟢 BAIXO - Limpeza de código

**Solução**: Remover código morto

---

## 📊 RESUMO DOS PROBLEMAS POR SEVERIDADE

### 🔴 Críticos (3)
1. ✅ Dados da API de CPF não são salvos completamente
2. ✅ Autocompletar de telefones não funciona
3. ✅ Endpoint `/api/calcular-preco` não implementado

### 🟡 Médios (3)
1. ✅ Endereços da API não são pré-preenchidos
2. ✅ Função de cálculo de preço duplicada
3. ✅ Fontes Rawline retornando 404

### 🟢 Baixos (3)
1. ✅ Imagens duplicadas em múltiplos diretórios
2. ✅ Console logs em produção
3. ✅ Código comentado não removido

---

## 🛠️ PLANO DE AÇÃO RECOMENDADO

### Prioridade 1 (Imediato)
1. **Salvar dados completos da API de CPF**
   - Modificar `/validar-dados/index.html`
   - Adicionar `localStorage.setItem('cpfData', JSON.stringify(data))`

2. **Implementar endpoint `/api/calcular-preco` no proxy**
   - Ou garantir que fallback local funciona corretamente

### Prioridade 2 (Curto prazo)
1. **Pré-preencher endereços quando disponíveis**
   - Adicionar função em `/endereco/index.html`

2. **Remover lógica duplicada de cálculo de preço**
   - Escolher: API ou local
   - Remover o outro

### Prioridade 3 (Médio prazo)
1. **Centralizar imagens e recursos**
   - Criar `/assets/` centralizado
   - Remover duplicatas

2. **Limpar código**
   - Remover console.logs
   - Remover código comentado
   - Adicionar minificação para produção

---

## 📝 OBSERVAÇÕES FINAIS

### Pontos Positivos
✅ Estrutura HTML bem organizada
✅ Código de autocompletar já implementado
✅ Sistema de navegação linear funciona
✅ Integração com API de CPF está funcional
✅ localStorage usado adequadamente para persistência

### Pontos de Atenção
⚠️ **Dados valiosos estão sendo desperdiçados**
⚠️ Funcionalidades prontas não funcionam por falta de dados
⚠️ Usuário tem experiência pior do que poderia ter

### Recomendação Geral
Este projeto está **85% pronto**, mas os 15% faltantes são **críticos** para a experiência do usuário. A correção principal (salvar cpfData completo) é simples e desbloqueará várias funcionalidades já implementadas.

---

## 📞 PRÓXIMOS PASSOS

1. ✅ Revisar este relatório
2. ⬜ Priorizar correções
3. ⬜ Implementar correção do problema crítico #1
4. ⬜ Testar fluxo completo após correção
5. ⬜ Implementar melhorias secundárias

---

**Fim do Relatório**
