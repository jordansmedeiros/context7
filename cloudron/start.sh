#!/bin/bash
set -eu

echo "=== Context7 MCP Server - Cloudron Entrypoint ==="

# --- Memory limit ---
if [ -n "${CLOUDRON_MEMORY_LIMIT:-}" ]; then
    MAX_MEM=$(( CLOUDRON_MEMORY_LIMIT * 80 / 100 ))
    export NODE_OPTIONS="--max-old-space-size=${MAX_MEM} ${NODE_OPTIONS:-}"
    echo "[env] NODE_OPTIONS=${NODE_OPTIONS}"
fi

# --- App URL (Cloudron fornece automaticamente) ---
if [ -n "${CLOUDRON_APP_ORIGIN:-}" ]; then
    export APP_URL="${CLOUDRON_APP_ORIGIN}"
    echo "[env] APP_URL=${APP_URL}"
fi

# --- Validacao de variaveis obrigatorias ---
if [ -z "${CONTEXT7_API_KEY:-}" ]; then
    echo "[WARN] CONTEXT7_API_KEY nao definida - servidor funcionara sem autenticacao de API key em modo stdio"
fi

# --- Log das variaveis configuradas (sem expor valores secretos) ---
echo "[env] CONTEXT7_API_KEY=${CONTEXT7_API_KEY:+SET}"
echo "[env] CONTEXT7_API_URL=${CONTEXT7_API_URL:-default}"
echo "[env] RESOURCE_URL=${RESOURCE_URL:-default}"
echo "[env] AUTH_SERVER_URL=${AUTH_SERVER_URL:-default}"
echo "[env] CLIENT_IP_ENCRYPTION_KEY=${CLIENT_IP_ENCRYPTION_KEY:+SET}"

echo "=== Starting Context7 MCP Server on port 8080 ==="
exec node dist/index.js --transport http --port 8080
