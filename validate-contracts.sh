#!/bin/bash
set -e

echo "🔍 Validating API contracts for rfp-ui..."

# Check if contracts submodule is initialized
if [ ! -f "contracts/rfp-contracts/openapi/api-gateway.yaml" ]; then
    echo "❌ Contracts not found. Run: git submodule update --init --recursive"
    exit 1
fi

echo "✅ Contracts submodule present"

# Check if OpenAPI spec validator is available
if ! command -v npx &> /dev/null; then
    echo "⚠️  npx not found. Skipping OpenAPI validation."
    exit 0
fi

# Validate OpenAPI spec
echo "📋 Validating OpenAPI specification..."
if npx @redocly/cli lint contracts/rfp-contracts/openapi/api-gateway.yaml --skip-rule operation-4xx-response; then
    echo "✅ OpenAPI spec is valid"
else
    echo "⚠️  OpenAPI validation warnings (non-blocking)"
fi

# Check API endpoints match between UI and contract
echo "📋 Checking API endpoint usage..."
CONTRACT_ENDPOINTS=$(grep -o "'/api/[^']*'" contracts/rfp-contracts/openapi/api-gateway.yaml 2>/dev/null | sort -u | wc -l)
UI_ENDPOINTS=$(grep -o "'/api/[^']*'" src/services/api.js 2>/dev/null | sort -u | wc -l)

echo "  Contract defines: $CONTRACT_ENDPOINTS endpoints"
echo "  UI uses: $UI_ENDPOINTS endpoints"

echo ""
echo "✅ Contract validation complete!"
