#!/bin/bash
set -eu

# ============================================================
# Context7 - Deploy via Build Local (Docker local + push)
# ============================================================

APP_DOMAIN="context7.sinesys.online"
CLOUDRON_URL="https://my.sinesys.online"
REGISTRY="registry.sinesys.online"
IMAGE_NAME="${REGISTRY}/context7"
TAG="${1:-latest}"

# --- Flags ---
SKIP_BUILD=false
ENV_ONLY=false
NO_CACHE=""

for arg in "$@"; do
    case $arg in
        --skip-build) SKIP_BUILD=true ;;
        --env-only) ENV_ONLY=true ;;
        --no-cache) NO_CACHE="--no-cache" ;;
    esac
done

echo "=== Context7 - Deploy Local ==="
echo "App:      ${APP_DOMAIN}"
echo "Image:    ${IMAGE_NAME}:${TAG}"
echo "Flags:    skip-build=${SKIP_BUILD} env-only=${ENV_ONLY} no-cache=${NO_CACHE:-false}"
echo ""

# --- Verificar ferramentas ---
if ! command -v cloudron &> /dev/null; then
    echo "[ERRO] Cloudron CLI nao encontrado. Instale com: npm install -g cloudron"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "[ERRO] Docker nao encontrado."
    exit 1
fi

# --- Apenas envs ---
if [ "$ENV_ONLY" = true ]; then
    echo "[ENV] Configurando apenas variaveis de ambiente..."
    if [ -f .env.cloudron ]; then
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            echo "  -> ${key}"
            cloudron env set --app "${APP_DOMAIN}" "${key}=${value}"
        done < .env.cloudron
        echo "[OK] Variaveis configuradas."
    else
        echo "[ERRO] .env.cloudron nao encontrado."
        exit 1
    fi
    exit 0
fi

# --- Verificar login ---
echo "[1/5] Verificando login..."
cloudron list --server "${CLOUDRON_URL}" > /dev/null 2>&1 || {
    echo "[INFO] Fazendo login no Cloudron..."
    cloudron login "${CLOUDRON_URL}"
}

# --- Build ---
if [ "$SKIP_BUILD" = false ]; then
    echo "[2/5] Build Docker (linux/amd64)..."
    docker build \
        --platform linux/amd64 \
        -f Dockerfile.cloudron \
        -t "${IMAGE_NAME}:${TAG}" \
        ${NO_CACHE} \
        .

    echo "[3/5] Push para registry..."
    docker push "${IMAGE_NAME}:${TAG}"
else
    echo "[2/5] Build pulado (--skip-build)"
    echo "[3/5] Push pulado (--skip-build)"
fi

# --- Install ou Update ---
echo "[4/5] Verificando se o app existe..."
if cloudron list --server "${CLOUDRON_URL}" 2>/dev/null | grep -q "${APP_DOMAIN}"; then
    echo "[INFO] App encontrado - atualizando..."
    cloudron update --app "${APP_DOMAIN}" --image "${IMAGE_NAME}:${TAG}"
else
    echo "[INFO] App nao encontrado - instalando pela primeira vez..."
    cloudron install --app "${APP_DOMAIN}" --image "${IMAGE_NAME}:${TAG}"
fi

# --- Variaveis de ambiente ---
echo "[5/5] Configurando variaveis de ambiente..."
if [ -f .env.cloudron ]; then
    echo "[INFO] Lendo variaveis de .env.cloudron..."
    while IFS='=' read -r key value; do
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
