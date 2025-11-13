# HashiCorp Vault Integration Example

This example demonstrates how to use HashiCorp Vault to inject PostgreSQL and Redis credentials into Orkes Conductor pods securely.

## Quick Start

### 2. Store PostgreSQL and Redis Secrets in Vault

Store your actual database and Redis credentials:

```bash
# Enable KV secrets engine (if not already enabled)
vault secrets enable -path=secret kv-v2

# Store PostgreSQL credentials
vault kv put secret/orkes/postgres \
  host="your-postgres-host.example.com" \
  port="5432" \
  database="conductor" \
  username="conductor_user" \
  password="your-secure-postgres-password"

# Store Redis credentials
vault kv put secret/orkes/redis \
  host="your-redis-host.example.com" \
  port="6379" \
  password="your-secure-redis-password"
```

**For testing with local PostgreSQL/Redis:**

```bash
# If you're using the Evaluation setup with in-cluster PostgreSQL and Redis
vault kv put secret/orkes/postgres \
  host="postgres-postgresql.orkes-conductor.svc.cluster.local" \
  port="5432" \
  database="conductor" \
  username="postgres" \
  password="postgres123"

vault kv put secret/orkes/redis \
  host="redis-master.orkes-conductor.svc.cluster.local" \
  port="6379" \
  password="redis123"
```

### 3. Create Vault Policies

Create policies that grant read access to the secrets:

```bash
# Policy for Conductor (needs access to both postgres and redis)
vault policy write orkes-conductor - <<EOF
path "secret/data/orkes/postgres" {
  capabilities = ["read"]
}
path "secret/data/orkes/redis" {
  capabilities = ["read"]
}
EOF

# Policy for Workers (same access as conductor)
vault policy write orkes-workers - <<EOF
path "secret/data/orkes/postgres" {
  capabilities = ["read"]
}
path "secret/data/orkes/redis" {
  capabilities = ["read"]
}
EOF
```

### 4. Create Vault Roles for Kubernetes Service Accounts

Map Kubernetes service accounts to Vault policies:

```bash
# Create Vault role for Conductor
vault write auth/kubernetes/role/orkes-conductor \
  bound_service_account_names=conductor-app \
  bound_service_account_namespaces=orkes-conductor \
  policies=orkes-conductor \
  ttl=24h

# Create Vault role for Workers
vault write auth/kubernetes/role/orkes-workers \
  bound_service_account_names=conductor-workers-app \
  bound_service_account_namespaces=orkes-conductor \
  policies=orkes-workers \
  ttl=24h
```

## Usage

### Option 1: Using Helm with values file

Install the chart with the Vault-enabled values file and properties files configured for Vault:

```bash
helm install orkes-conductor orkesio/orkes-conductor \
  --namespace orkes-conductor \
  --create-namespace \
  -f values-vault.yaml \
  --set-file conductor.properties=conductor.properties \
  --set-file workers.properties=workers.properties
```

**Note:** The `conductor.properties` and `workers.properties` files in this directory are configured to use environment variables (e.g., `${DB_HOST}`, `${DB_PASSWORD}`) that will be injected by Vault.

### Option 2: Using ArgoCD

Store the configuration files in a Git repository and reference them in ArgoCD:

**Repository Structure:**
```
your-config-repo/
├── orkes/
│   ├── conductor.properties  # With ${DB_HOST}, ${DB_PASSWORD} variables
│   └── workers.properties    # With environment variable placeholders
```

**ArgoCD Application:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: orkes-conductor
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://orkes-io.github.io/orkes-helm-charts
    chart: orkes-conductor
    targetRevision: 3.0.0
    helm:
      fileParameters:
        - name: conductor.properties
          path: orkes/conductor.properties  # From your config repo
        - name: workers.properties
          path: orkes/workers.properties
      parameters:
        - name: vault.enabled
          value: "true"
        - name: vault.conductor.enabled
          value: "true"
        - name: vault.conductor.role
          value: "orkes-conductor"
        - name: vault.workers.enabled
          value: "true"
        - name: vault.workers.role
          value: "orkes-workers"
      values: |
        vault:
          conductor:
            annotations:
              vault.hashicorp.com/agent-inject-secret-postgres: "secret/data/orkes/postgres"
              vault.hashicorp.com/agent-inject-template-postgres: |
                {{- with secret "secret/data/orkes/postgres" -}}
                export DB_HOST="{{ .Data.data.host }}"
                export DB_PORT="{{ .Data.data.port }}"
                export DB_NAME="{{ .Data.data.database }}"
                export DB_USER="{{ .Data.data.username }}"
                export DB_PASSWORD="{{ .Data.data.password }}"
                {{- end }}
              vault.hashicorp.com/agent-inject-secret-redis: "secret/data/orkes/redis"
              vault.hashicorp.com/agent-inject-template-redis: |
                {{- with secret "secret/data/orkes/redis" -}}
                export REDIS_HOST="{{ .Data.data.host }}"
                export REDIS_PORT="{{ .Data.data.port }}"
                export REDIS_PASSWORD="{{ .Data.data.password }}"
                {{- end }}
              vault.hashicorp.com/preserve-secret-case: "true"
          workers:
            annotations:
              vault.hashicorp.com/agent-inject-secret-postgres: "secret/data/orkes/postgres"
              vault.hashicorp.com/agent-inject-template-postgres: |
                {{- with secret "secret/data/orkes/postgres" -}}
                export DB_HOST="{{ .Data.data.host }}"
                export DB_PORT="{{ .Data.data.port }}"
                export DB_NAME="{{ .Data.data.database }}"
                export DB_USER="{{ .Data.data.username }}"
                export DB_PASSWORD="{{ .Data.data.password }}"
                {{- end }}
              vault.hashicorp.com/agent-inject-secret-redis: "secret/data/orkes/redis"
              vault.hashicorp.com/agent-inject-template-redis: |
                {{- with secret "secret/data/orkes/redis" -}}
                export REDIS_HOST="{{ .Data.data.host }}"
                export REDIS_PORT="{{ .Data.data.port }}"
                export REDIS_PASSWORD="{{ .Data.data.password }}"
                {{- end }}
              vault.hashicorp.com/preserve-secret-case: "true"
  destination:
    server: https://kubernetes.default.svc
    namespace: orkes-conductor
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## How It Works

1. **Pod Startup**: When a Conductor or Workers pod starts, the Vault Agent Injector webhook detects the Vault annotations
2. **Agent Injection**: An init container (vault-agent-init) and sidecar container (vault-agent) are automatically added to the pod
3. **Authentication**: The Vault agent authenticates with Vault using the pod's Kubernetes service account token
4. **Secret Retrieval**: Vault fetches the PostgreSQL and Redis secrets from the configured paths (`secret/data/orkes/postgres` and `secret/data/orkes/redis`)
5. **Template Rendering**: The Vault agent renders the templates, creating shell scripts with `export` statements
6. **File Writing**: Secrets are written to `/vault/secrets/` in the pod as shell scripts
7. **Environment Loading**: The application sources these files at startup, making the environment variables available
8. **Property Resolution**: Spring Boot (used by Conductor) resolves `${DB_HOST}`, `${DB_PASSWORD}`, etc. from environment variables

## File Structure After Vault Injection

Secrets are injected as files in the `/vault/secrets/` directory:

- `/vault/secrets/postgres` - PostgreSQL connection details (exported as `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`)
- `/vault/secrets/redis` - Redis connection details (exported as `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`)

**Example of `/vault/secrets/postgres`:**
```bash
export DB_HOST="postgres.example.com"
export DB_PORT="5432"
export DB_NAME="conductor"
export DB_USER="conductor_user"
export DB_PASSWORD="super-secure-password"
```

**Example of `/vault/secrets/redis`:**
```bash
export REDIS_HOST="redis.example.com"
export REDIS_PORT="6379"
export REDIS_PASSWORD="redis-secure-password"
```

These files are automatically sourced before the application starts, making the variables available to the properties files.

## Verifying the Setup

### 1. Verify Secrets in Vault

Check that your secrets are stored correctly:

```bash
# Verify PostgreSQL secrets
vault kv get secret/orkes/postgres

# Verify Redis secrets
vault kv get secret/orkes/redis
```

### 2. Check Vault Agent Injection

After deploying Conductor, verify the Vault agent was injected:

```bash
# List pods - should show 2/2 containers (app + vault-agent)
kubectl get pods -n orkes-conductor

# Example output:
# NAME                                    READY   STATUS    RESTARTS   AGE
# orkes-conductor-conductor-0             2/2     Running   0          5m
# orkes-conductor-workers-0               2/2     Running   0          5m
```

### 3. Verify Secrets Were Injected

Check that the secret files exist in the pod:

```bash
# Check conductor pod
kubectl exec -n orkes-conductor orkes-conductor-conductor-0 -c orkes-conductor -- ls -la /vault/secrets/

# Should show:
# postgres
# redis

# View the actual secrets (be careful in production!)
kubectl exec -n orkes-conductor orkes-conductor-conductor-0 -c orkes-conductor -- cat /vault/secrets/postgres
```

### 4. Verify Environment Variables

Confirm that environment variables are available to the application:

```bash
# Check if DB_HOST is set
kubectl exec -n orkes-conductor orkes-conductor-conductor-0 -c orkes-conductor -- env | grep DB_

# Should show:
# DB_HOST=postgres.example.com
# DB_PORT=5432
# DB_NAME=conductor
# DB_USER=conductor_user
# DB_PASSWORD=***
```

## Customization

### Using Different Vault Paths

If your secrets are stored in different Vault paths, update the annotations:

```yaml
vault:
  conductor:
    annotations:
      vault.hashicorp.com/agent-inject-secret-postgres: "secret/data/my-app/database"
      vault.hashicorp.com/agent-inject-secret-redis: "secret/data/my-app/cache"
```

### Adding Additional Secrets

You can inject additional secrets (e.g., Elasticsearch, external APIs):

```yaml
vault:
  conductor:
    annotations:
      vault.hashicorp.com/agent-inject-secret-elasticsearch: "secret/data/orkes/elasticsearch"
      vault.hashicorp.com/agent-inject-template-elasticsearch: |
        {{- with secret "secret/data/orkes/elasticsearch" -}}
        export ELASTICSEARCH_URL="{{ .Data.data.url }}"
        export ELASTICSEARCH_USER="{{ .Data.data.username }}"
        export ELASTICSEARCH_PASSWORD="{{ .Data.data.password }}"
        {{- end }}
```

### Vault Enterprise Features

For Vault Enterprise, you can specify namespaces:

```yaml
vault:
  conductor:
    annotations:
      vault.hashicorp.com/namespace: "my-organization/my-team"
```

## Troubleshooting

### Vault Agent Not Injecting

**Problem**: Pods show 1/1 containers instead of 2/2

**Solutions**:
1. Verify Vault injector is running:
   ```bash
   kubectl get pods -n vault -l app.kubernetes.io/name=vault-agent-injector
   ```

2. Check if annotations are correct:
   ```bash
   kubectl describe pod -n orkes-conductor <pod-name> | grep vault
   ```

3. Check Vault injector logs:
   ```bash
   kubectl logs -n vault -l app.kubernetes.io/name=vault-agent-injector
   ```

### Authentication Failures

**Problem**: Pod fails to start or shows vault-agent errors

**Solutions**:
1. Check Vault agent logs:
   ```bash
   kubectl logs -n orkes-conductor <pod-name> -c vault-agent-init
   kubectl logs -n orkes-conductor <pod-name> -c vault-agent
   ```

2. Verify the Kubernetes auth role exists:
   ```bash
   vault read auth/kubernetes/role/orkes-conductor
   ```

3. Check service account exists:
   ```bash
   kubectl get sa -n orkes-conductor conductor-app
   ```

### Secrets Not Available

**Problem**: Application can't connect to database/Redis

**Solutions**:
1. Verify secrets exist in Vault:
   ```bash
   vault kv get secret/orkes/postgres
   vault kv get secret/orkes/redis
   ```

2. Check if secrets are mounted:
   ```bash
   kubectl exec -n orkes-conductor <pod-name> -c orkes-conductor -- cat /vault/secrets/postgres
   kubectl exec -n orkes-conductor <pod-name> -c orkes-conductor -- cat /vault/secrets/redis
   ```

3. Check application logs for connection errors:
   ```bash
   kubectl logs -n orkes-conductor <pod-name> -c orkes-conductor
   ```

### Permission Denied Errors

**Problem**: Vault agent can't read secrets

**Solutions**:
1. Verify Vault policy allows read access:
   ```bash
   vault policy read orkes-conductor
   ```

2. Ensure the role is bound to the correct service account:
   ```bash
   vault read auth/kubernetes/role/orkes-conductor
   ```

3. Check if the service account name matches:
   ```bash
   kubectl get pod <pod-name> -o jsonpath='{.spec.serviceAccountName}'
   ```

## Resources

- [Vault Agent Injector Documentation](https://developer.hashicorp.com/vault/docs/platform/k8s/injector)
- [Vault Agent Injector Annotations](https://developer.hashicorp.com/vault/docs/platform/k8s/injector/annotations)
- [Kubernetes Auth Method](https://developer.hashicorp.com/vault/docs/auth/kubernetes)
