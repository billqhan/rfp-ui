#!/bin/bash

# Deploy Web UI Script - Bash Version
# This script builds and deploys the React web UI to S3

# Load environment configuration from project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../.env.dev" ]; then
    source "$SCRIPT_DIR/../.env.dev"
fi

BUCKET_NAME="${1:-${UI_BUCKET:-${BUCKET_PREFIX:+${BUCKET_PREFIX}-}rfp-ui-${ENVIRONMENT:-dev}}}"
REGION="${2:-${REGION:-us-east-1}}"
CREATE_BUCKET="${3:-false}"

# Guard: bucket name must not be empty
if [ -z "$BUCKET_NAME" ]; then
    echo "❌ Bucket name is empty. Provide bucket arg or set UI_BUCKET or BUCKET_PREFIX/ENVIRONMENT variables."
    echo "Usage: ./deploy.sh <bucket-name> [region] [create-bucket-true|false]"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║          WEB UI DEPLOYMENT SCRIPT                     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if bucket exists (should be created by CloudFormation with CloudFront)
echo "[1/4] Checking S3 bucket..."
if aws s3 ls "s3://$BUCKET_NAME" --region $REGION >/dev/null 2>&1; then
    echo "  ✅ Bucket exists: $BUCKET_NAME"
else
    echo "  ❌ Bucket not found: $BUCKET_NAME"
    echo "  ℹ️  The S3 bucket should be created by CloudFormation infrastructure stack."
    echo "  ℹ️  Run the infrastructure deployment first: ./rfp-infrastructure/scripts/deploy-infra.sh dev"
    exit 1
fi

# Install dependencies
echo ""
echo "[2/4] Installing dependencies..."
npm install
echo "  ✅ Dependencies installed"

# Build the project
echo ""
echo "[3/4] Building React application..."
npm run build
echo "  ✅ Build completed"

# Deploy to S3
echo ""
echo "[4/4] Deploying to S3..."
aws s3 sync dist/ "s3://$BUCKET_NAME" --delete --region $REGION
echo "  ✅ Deployment completed"

# Invalidate CloudFront cache if distribution exists
echo ""
echo "[5/5] Checking for CloudFront distribution..."
CLOUDFRONT_ID=$(aws cloudformation describe-stacks \
    --stack-name "rfp-${ENVIRONMENT:-dev}-master" \
    --region us-east-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
    --output text 2>/dev/null || echo "")

if [ -n "$CLOUDFRONT_ID" ] && [ "$CLOUDFRONT_ID" != "None" ]; then
    echo "  🔄 Invalidating CloudFront cache for distribution: $CLOUDFRONT_ID"
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$INVALIDATION_ID" ]; then
        echo "  ✅ CloudFront invalidation created: $INVALIDATION_ID"
        CLOUDFRONT_URL="https://$(aws cloudfront get-distribution --id "$CLOUDFRONT_ID" --query 'Distribution.DomainName' --output text)"
        echo "  🌐 CloudFront URL: $CLOUDFRONT_URL"
    fi
else
    echo "  ℹ️  No CloudFront distribution found"
fi

echo ""
echo "🎉 Deployment Successful!"
if [ -n "$CLOUDFRONT_URL" ]; then
    echo "   🌐 CloudFront URL: $CLOUDFRONT_URL"
    echo "   ℹ️  Changes will be visible after cache invalidation completes (1-3 minutes)"
else
    echo "   📦 Files uploaded to S3: s3://$BUCKET_NAME"
    echo "   ℹ️  Access via CloudFront distribution (check CloudFormation outputs)"
fi
echo ""