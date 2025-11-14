#!/bin/bash
# Quick setup script for Vault integration with Orkes Conductor
# This script sets up Vault policies, roles, and stores initial secrets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-orkes-conductor}"
VAULT_NAMESPACE="${VAULT_NAMESPACE:-vault}"

echo -e "${GREEN}=== Orkes Conductor Vault Setup ===${NC}"
echo ""

# Check if vault CLI is available
if ! command -v vault &> /dev/null; then
    echo -e "${RED}Error: vault CLI not found. Please install it first.${NC}"
    echo "Visit: https://developer.hashicorp.com/vault/downloads"
    exit 1
fi

echo -e "${YELLOW}Step 1: Enabling Kubernetes authentication${NC}"
vault auth enable kubernetes 2>/dev/null || echo "Kubernetes auth already enabled"

echo -e "${YELLOW}Step 2: Configuring Kubernetes auth method${NC}"
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT" || true

echo ""
echo -e "${YELLOW}Step 3: Creating Vault policies${NC}"

# Create Conductor policy
vault policy write orkes-conductor - <<EOF
path "secret/data/orkes/postgres" {
  capabilities = ["read"]
}
path "secret/data/orkes/redis" {
  capabilities = ["read"]
}
EOF
echo "✓ Created orkes-conductor policy"

# Create Workers policy
vault policy write orkes-workers - <<EOF
path "secret/data/orkes/postgres" {
  capabilities = ["read"]
}
path "secret/data/orkes/redis" {
  capabilities = ["read"]
}
EOF
echo "✓ Created orkes-workers policy"

echo ""
echo -e "${YELLOW}Step 4: Creating Vault roles for Kubernetes service accounts${NC}"

# Create Conductor role
vault write auth/kubernetes/role/orkes-conductor \
    bound_service_account_names=conductor-app \
    bound_service_account_namespaces=$NAMESPACE \
    policies=orkes-conductor \
    ttl=24h
echo "✓ Created orkes-conductor role"

# Create Workers role
vault write auth/kubernetes/role/orkes-workers \
    bound_service_account_names=conductor-workers-app \
    bound_service_account_namespaces=$NAMESPACE \
    policies=orkes-workers \
    ttl=24h
echo "✓ Created orkes-workers role"

echo ""
echo -e "${YELLOW}Step 5: Storing secrets in Vault${NC}"
echo "You can now store your secrets. Here are examples:"
echo ""

echo -e "${GREEN}For production PostgreSQL:${NC}"
echo "vault kv put secret/orkes/postgres \\"
echo "  host=\"your-postgres-host.example.com\" \\"
echo "  port=\"5432\" \\"
echo "  database=\"conductor\" \\"
echo "  username=\"conductor_user\" \\"
echo "  password=\"your-secure-password\""
echo ""

echo -e "${GREEN}For production Redis:${NC}"
echo "vault kv put secret/orkes/redis \\"
echo "  host=\"your-redis-host.example.com\" \\"
echo "  port=\"6379\" \\"
echo "  password=\"your-redis-password\""
echo ""

read -p "Do you want to store test/dev secrets now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Storing test/dev secrets...${NC}"

    # PostgreSQL test secrets
    read -p "PostgreSQL host [postgres-postgresql.$NAMESPACE.svc.cluster.local]: " PG_HOST
    PG_HOST=${PG_HOST:-postgres-postgresql.$NAMESPACE.svc.cluster.local}

    read -p "PostgreSQL port [5432]: " PG_PORT
    PG_PORT=${PG_PORT:-5432}

    read -p "PostgreSQL database [conductor]: " PG_DB
    PG_DB=${PG_DB:-conductor}

    read -p "PostgreSQL username [postgres]: " PG_USER
    PG_USER=${PG_USER:-postgres}

    read -sp "PostgreSQL password: " PG_PASS
    echo

    vault kv put secret/orkes/postgres \
        host="$PG_HOST" \
        port="$PG_PORT" \
        database="$PG_DB" \
        username="$PG_USER" \
        password="$PG_PASS"
    echo "✓ Stored PostgreSQL secrets"

    # Redis test secrets
    echo ""
    read -p "Redis host [redis-master.$NAMESPACE.svc.cluster.local]: " REDIS_HOST
    REDIS_HOST=${REDIS_HOST:-redis-master.$NAMESPACE.svc.cluster.local}

    read -p "Redis port [6379]: " REDIS_PORT
    REDIS_PORT=${REDIS_PORT:-6379}

    read -sp "Redis password: " REDIS_PASS
    echo

    vault kv put secret/orkes/redis \
        host="$REDIS_HOST" \
        port="$REDIS_PORT" \
        password="$REDIS_PASS"
    echo "✓ Stored Redis secrets"
fi

echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo "Next steps:"
echo "1. Deploy Orkes Conductor with Vault enabled:"
echo "   helm install orkes-conductor orkesio/orkes-conductor \\"
echo "     --namespace $NAMESPACE \\"
echo "     -f values-vault.yaml"
echo ""
echo "   (No need for --set-file! Properties are embedded in values-vault.yaml)"
echo ""
echo "2. Verify secrets were injected:"
echo "   kubectl get pods -n $NAMESPACE"
echo "   # Wait for pods to show 2/2 containers (app + vault-agent)"
echo ""
echo "   kubectl exec -n $NAMESPACE <pod-name> -c orkes-conductor -- cat /vault/secrets/postgres"
echo ""
echo "3. Check application logs:"
echo "   kubectl logs -n $NAMESPACE <pod-name> -c orkes-conductor"
echo ""
