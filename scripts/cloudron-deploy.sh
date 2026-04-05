#!/bin/bash
set -eu

# ============================================================
# Context7 - Deploy via Build Service (Cloudron remoto)
# ============================================================

APP_DOMAIN="context7.sinesys.online"
CLOUDRON_URL="https://my.sinesys.online"
BUILD_SERVICE="https://builder.sinesys.online"
BUILD_SERVICE_TOKEN="bde253a143ffa41cbe512632df128fc87f59029953c26333"

echo "=== Context7 - Deploy via Build Service ==="
echo "App: ${APP_DOMAIN}"
echo ""

# --- Verificar Cloudron CLI ---
if ! command -v cloudron &> /dev/null; then
    echo "[ERRO] Cloudron CLI nao encontrado. Instale com: npm install -g cloudron"
    exit 1
fi

# --- Verificar login ---
echo "[1/4] Verificando login no Cloudron..."
cloudron list --server "${CLOUDRON_URL}" > /dev/null 2>&1 || {
    echo "[INFO] Fazendo login no Cloudron..."
    cloudron login "${CLOUDRON_URL}"
}

# --- Build remoto ---
echo "[2/4] Iniciando build remoto via Build Service..."
cloudron build \
    --set-build-service "${BUILD_SERVICE}" \
    --build-service-token "${BUILD_SERVICE_TOKEN}" \
    --docker-file Dockerfile.cloudron

# --- Verificar se app ja existe ---
echo "[3/4] Verificando se o app existe..."
if cloudron list --server "${CLOUDRON_URL}" 2>/dev/null | grep -q "${APP_DOMAIN}"; then
    echo "[INFO] App encontrado - atualizando..."
    cloudron update --app "${APP_DOMAIN}"
else
    echo "[INFO] App nao encontrado - instalando pela primeira vez..."
    cloudron install --app "${APP_DOMAIN}"
fi

# --- Setar variaveis de ambiente ---
echo "[4/4] Configurando variaveis de ambiente..."
if [ -f .env.cloudron ]; then
    echo "[INFO] Lendo variaveis de .env.cloudron..."
    while IFS='=' read -r key value; do
        # Ignora linhas vazias e comentarios
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        echo "  -> ${key}"
        cloudron env set --app "${APP_DOMAIN}" "${key}=${value}"
    done < .env.cloudron
else
    echo "[WARN] .env.cloudron nao encontrado - configure manualmente:"
    echo "  cloudron env set --app ${APP_DOMAIN} CONTEXT7_API_KEY=ctx7sk..."
    echo "  cloudron env set --app ${APP_DOMAIN} CLIENT_IP_ENCRYPTION_KEY=..."
fi

echo ""
echo "=== Deploy concluido! ==="
echo "App URL: https://${APP_DOMAIN}"
echo "Health:  https://${APP_DOMAIN}/ping"
echo "MCP:     https://${APP_DOMAIN}/mcp"
echo ""
echo "Logs: cloudron logs -f --app ${APP_DOMAIN}"
