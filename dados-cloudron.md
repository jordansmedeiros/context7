# Cloudron - Context7 MCP Server

## Acesso

- Painel: https://my.sinesys.online
- Usuario: jordan.medeiros
- Senha: Jsm87231988@*&@
- Registry: https://registry.sinesys.online/
- Build Service: https://builder.sinesys.online
- Build Service Token: bde253a143ffa41cbe512632df128fc87f59029953c26333
- App Domain: context7.sinesys.online

## Scripts Automatizados

### Deploy completo (build local + push + install/update + env set)

```bash
./scripts/cloudron-deploy-local.sh
```

### Deploy completo (build remoto via Build Service)

```bash
./scripts/cloudron-deploy.sh
```

### Apenas update + env set (sem rebuild)

```bash
./scripts/cloudron-deploy-local.sh --skip-build
```

### Apenas variaveis de ambiente

```bash
./scripts/cloudron-deploy-local.sh --env-only
```

### Build sem cache Docker

```bash
./scripts/cloudron-deploy-local.sh --no-cache
```

## Primeira Instalacao (Passo a Passo)

1. Instalar Cloudron CLI:
   ```bash
   npm install -g cloudron
   ```

2. Login no Cloudron:
   ```bash
   cloudron login https://my.sinesys.online
   ```

3. Login no Registry Docker:
   ```bash
   docker login registry.sinesys.online
   # user: jordan.medeiros
   ```

4. Criar `.env.cloudron` (copiar de `.env.cloudron.example`):
   ```bash
   cp .env.cloudron.example .env.cloudron
   # Editar e preencher CONTEXT7_API_KEY e CLIENT_IP_ENCRYPTION_KEY
   ```

5. Rodar o deploy:
   ```bash
   ./scripts/cloudron-deploy-local.sh
   ```

6. Verificar:
   ```bash
   # Health check
   curl https://context7.sinesys.online/ping

   # Logs
   cloudron logs -f --app context7.sinesys.online
   ```

## Comandos Manuais

### Build remoto (via Build Service)

```bash
cloudron build --set-build-service 'https://builder.sinesys.online' --build-service-token bde253a143ffa41cbe512632df128fc87f59029953c26333 --docker-file Dockerfile.cloudron
```

### Build local + Push

```bash
docker build --platform linux/amd64 -f Dockerfile.cloudron -t registry.sinesys.online/context7:latest .
docker push registry.sinesys.online/context7:latest
```

### Install do app (primeira vez)

```bash
cloudron install --app context7.sinesys.online --image registry.sinesys.online/context7:latest
```

### Update do app (apos build)

```bash
cloudron update --app context7.sinesys.online --image registry.sinesys.online/context7:latest
```

### Setar variaveis de ambiente

```bash
cloudron env set --app context7.sinesys.online CONTEXT7_API_KEY=ctx7sk...
cloudron env set --app context7.sinesys.online CLIENT_IP_ENCRYPTION_KEY=$(openssl rand -hex 32)
```

### Ver logs

```bash
cloudron logs -f --app context7.sinesys.online
```

### Listar apps

```bash
cloudron list
```

### Restart do app

```bash
cloudron restart --app context7.sinesys.online
```

### Ver variaveis de ambiente atuais

```bash
cloudron env get --app context7.sinesys.online
```

## Arquivos do Projeto

| Arquivo | Descricao |
|---|---|
| `CloudronManifest.json` | Manifest do app (stateless, sem addons) |
| `Dockerfile.cloudron` | Dockerfile multi-stage para Cloudron |
| `cloudron/start.sh` | Entrypoint - configura memory limit e inicia o servidor |
| `scripts/cloudron-deploy.sh` | Deploy automatizado (build remoto) |
| `scripts/cloudron-deploy-local.sh` | Deploy automatizado (build local) |
| `.env.cloudron.example` | Template das variaveis de ambiente |
| `.env.cloudron` | Variaveis de ambiente (NAO commitar!) |

## Variaveis de Ambiente

### Obrigatorias

| Variavel | Descricao |
|---|---|
| `CONTEXT7_API_KEY` | API key do Context7 (formato: `ctx7sk...`) |

### Recomendadas (producao)

| Variavel | Descricao |
|---|---|
| `CLIENT_IP_ENCRYPTION_KEY` | Chave AES-256 para encriptar IPs (64 hex chars). Gerar com: `openssl rand -hex 32` |

### Opcionais (tem defaults)

| Variavel | Default | Descricao |
|---|---|---|
| `CONTEXT7_API_URL` | `https://context7.com/api` | URL base da API |
| `RESOURCE_URL` | `https://mcp.context7.com` | URL do servidor MCP de recursos |
| `AUTH_SERVER_URL` | `https://context7.com` | URL do servidor de autenticacao |
| `HTTPS_PROXY` | - | Proxy HTTPS |
| `NODE_EXTRA_CA_CERTS` | - | Certificado CA customizado |

### Automaticas (Cloudron fornece)

| Variavel | Mapeamento no start.sh |
|---|---|
| `CLOUDRON_MEMORY_LIMIT` | -> `NODE_OPTIONS --max-old-space-size` (80% do limite) |
| `CLOUDRON_APP_ORIGIN` | -> `APP_URL` |

## Endpoints

| Endpoint | Descricao |
|---|---|
| `/ping` | Health check (usado pelo Cloudron) |
| `/mcp` | Endpoint principal MCP |
| `/mcp/oauth` | Endpoint MCP com OAuth |
| `/.well-known/oauth-protected-resource` | Metadata OAuth |
| `/.well-known/oauth-authorization-server` | Auth server proxy |

## Notas

- App **stateless** - sem banco de dados, sem Redis, sem email
- Sem addons do Cloudron necessarios
- Memory limit: 256MB (configuravel no manifest)
- Porta interna: 8080 (HTTP)
