# Custom Registry Configuration Guide

This guide shows how to configure Orkes Conductor to pull images from custom container registries.

## Supported Registry Patterns

The Helm chart supports multiple patterns for specifying custom registries, allowing flexibility for different enterprise setups.

### Pattern 1: Global Registry (Recommended for Single Registry)

Use a global registry that applies to both server and workers:

```yaml
global:
  image:
    registry: "myregistry.example.com"
    tag: "5.2.42"
    pullPolicy: Always
    pullSecrets:
      - name: my-registry-secret

server:
  image:
    repository: "myorg/orkes-conductor-server"

workers:
  image:
    repository: "myorg/orkes-conductor-workers"
```

**Result:**
- Server: `myregistry.example.com/myorg/orkes-conductor-server:5.2.42`
- Workers: `myregistry.example.com/myorg/orkes-conductor-workers:5.2.42`

### Pattern 2: Different Registries per Component

Use different registries for server and workers:

```yaml
global:
  image:
    tag: "5.2.42"

server:
  image:
    registry: "gcr.io/my-project"
    repository: "orkes-conductor-server"

workers:
  image:
    registry: "quay.io/myorg"
    repository: "orkes-conductor-workers"
```

**Result:**
- Server: `gcr.io/my-project/orkes-conductor-server:5.2.42`
- Workers: `quay.io/myorg/orkes-conductor-workers:5.2.42`

### Pattern 3: Full Image Name in Repository

Include the registry in the repository field:

```yaml
global:
  image:
    tag: "5.2.42"

server:
  image:
    repository: "myregistry.example.com/myorg/orkes-conductor-server"

workers:
  image:
    repository: "myregistry.example.com/myorg/orkes-conductor-workers"
```

**Result:**
- Server: `myregistry.example.com/myorg/orkes-conductor-server:5.2.42`
- Workers: `myregistry.example.com/myorg/orkes-conductor-workers:5.2.42`

## Cloud Provider Examples

### Azure Container Registry (ACR)

```yaml
global:
  image:
    registry: "myacr.azurecr.io"
    tag: "latest"
    pullSecrets:
      - name: acr-credentials

server:
  image:
    repository: "conductor/server"

workers:
  image:
    repository: "conductor/workers"
```

**Result:**
- Server: `myacr.azurecr.io/conductor/server:latest`
- Workers: `myacr.azurecr.io/conductor/workers:latest`

**Create ACR Pull Secret:**
```bash
kubectl create secret docker-registry acr-credentials \
  --docker-server=myacr.azurecr.io \
  --docker-username=<service-principal-id> \
  --docker-password=<service-principal-password> \
  --docker-email=<email>
```

### Google Container Registry (GCR)

```yaml
global:
  image:
    registry: "gcr.io/my-gcp-project"
    tag: "v1.0.0"
    pullSecrets:
      - name: gcr-json-key

server:
  image:
    repository: "orkes/conductor-server"

workers:
  image:
    repository: "orkes/conductor-workers"
```

**Result:**
- Server: `gcr.io/my-gcp-project/orkes/conductor-server:v1.0.0`
- Workers: `gcr.io/my-gcp-project/orkes/conductor-workers:v1.0.0`

**Create GCR Pull Secret:**
```bash
kubectl create secret docker-registry gcr-json-key \
  --docker-server=gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat gcr-key.json)" \
  --docker-email=<email>
```

### Amazon ECR

```yaml
global:
  image:
    registry: "123456789012.dkr.ecr.us-east-1.amazonaws.com"
    tag: "production"
    pullSecrets:
      - name: ecr-credentials

server:
  image:
    repository: "conductor-server"

workers:
  image:
    repository: "conductor-workers"
```

**Result:**
- Server: `123456789012.dkr.ecr.us-east-1.amazonaws.com/conductor-server:production`
- Workers: `123456789012.dkr.ecr.us-east-1.amazonaws.com/conductor-workers:production`

**Create ECR Pull Secret:**
```bash
# Get ECR login token
aws ecr get-login-password --region us-east-1 | \
kubectl create secret docker-registry ecr-credentials \
  --docker-server=123456789012.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password-stdin
```

### JFrog Artifactory

```yaml
global:
  image:
    registry: "mycompany.jfrog.io/docker-local"
    tag: "stable"
    pullSecrets:
      - name: jfrog-credentials

server:
  image:
    repository: "conductor-server"

workers:
  image:
    repository: "conductor-workers"
```

**Result:**
- Server: `mycompany.jfrog.io/docker-local/conductor-server:stable`
- Workers: `mycompany.jfrog.io/docker-local/conductor-workers:stable`

**Create JFrog Pull Secret:**
```bash
kubectl create secret docker-registry jfrog-credentials \
  --docker-server=mycompany.jfrog.io \
  --docker-username=<jfrog-username> \
  --docker-password=<jfrog-api-token> \
  --docker-email=<email>
```

### Harbor Registry

```yaml
global:
  image:
    registry: "harbor.example.com/conductor"
    tag: "2.0.0"
    pullSecrets:
      - name: harbor-credentials

server:
  image:
    repository: "server"

workers:
  image:
    repository: "workers"
```

**Result:**
- Server: `harbor.example.com/conductor/server:2.0.0`
- Workers: `harbor.example.com/conductor/workers:2.0.0`

## Advanced Scenarios

### Mixed Public and Private Images

```yaml
global:
  image:
    tag: "5.2.42"

server:
  # Public image from DockerHub
  image:
    repository: "orkesio/orkes-conductor-server"

workers:
  # Private image from custom registry
  image:
    registry: "myregistry.example.com"
    repository: "myorg/custom-conductor-workers"
    pullSecrets:
      - name: my-registry-secret
```

**Result:**
- Server: `orkesio/orkes-conductor-server:5.2.42` (DockerHub)
- Workers: `myregistry.example.com/myorg/custom-conductor-workers:5.2.42` (Custom)

### Different Tags for Server and Workers

```yaml
global:
  image:
    registry: "myregistry.example.com"

server:
  image:
    repository: "conductor-server"
    tag: "5.2.42"

workers:
  image:
    repository: "conductor-workers"
    tag: "5.2.40"  # Different version for workers
```

**Result:**
- Server: `myregistry.example.com/conductor-server:5.2.42`
- Workers: `myregistry.example.com/conductor-workers:5.2.40`

## Image Pull Secrets

### Method 1: Using global.image.pullSecrets (Recommended)

```yaml
global:
  image:
    registry: "myregistry.example.com"
    pullSecrets:
      - name: my-registry-secret
```

### Method 2: Using imageCredentials (Helm-managed)

```yaml
imageCredentials:
  enabled: true
  registry: "https://myregistry.example.com"
  username: "myuser"
  password: "mypassword"
  email: "user@example.com"
```

The chart creates a secret named `orkesregistry` automatically.

### Method 3: Using customImagePullSecrets (Multiple Registries)

```yaml
customImagePullSecrets:
  enabled: true
  name: "multi-registry-secret"
  registries:
    - registry: "registry1.example.com"
      username: "user1"
      password: "pass1"
      email: "user1@example.com"
    - registry: "registry2.example.com"
      username: "user2"
      password: "pass2"
      email: "user2@example.com"
```

### Method 4: Using Existing Secret

```yaml
existingImagePullSecret: "my-existing-secret"
```

## Testing Your Configuration

### Verify Image Names

```bash
helm template test . --values your-values.yaml | grep "image:" | head -5
```

Expected output:
```
image: "myregistry.example.com/myorg/orkes-conductor-server:5.2.42"
image: "myregistry.example.com/myorg/orkes-conductor-workers:5.2.42"
```

### Verify Image Pull Secrets

```bash
helm template test . --values your-values.yaml | grep "imagePullSecrets" -A 2
```

Expected output:
```yaml
imagePullSecrets:
  - name: my-registry-secret
```

### Test Pull Secret Creation

If using `imageCredentials` or `customImagePullSecrets`:

```bash
helm template test . --values your-values.yaml | grep "kind: Secret" -A 5
```

## Common Registry URLs

| Provider | Registry URL Format | Example |
|----------|-------------------|---------|
| DockerHub | N/A or `docker.io` | `docker.io/orkesio/conductor` |
| Azure ACR | `<name>.azurecr.io` | `myacr.azurecr.io/conductor` |
| Google GCR | `gcr.io/<project>` | `gcr.io/my-project/conductor` |
| Google Artifact Registry | `<region>-docker.pkg.dev/<project>/<repo>` | `us-central1-docker.pkg.dev/proj/repo/conductor` |
| Amazon ECR | `<account>.dkr.ecr.<region>.amazonaws.com` | `123456.dkr.ecr.us-east-1.amazonaws.com/conductor` |
| JFrog Artifactory | `<name>.jfrog.io/<repo>` | `mycompany.jfrog.io/docker-local/conductor` |
| Harbor | `<harbor-host>/<project>` | `harbor.example.com/conductor` |
| Quay.io | `quay.io/<namespace>` | `quay.io/myorg/conductor` |
| GitHub Container Registry | `ghcr.io/<owner>` | `ghcr.io/myorg/conductor` |

## Complete Example: Production with Private Registry

```yaml
global:
  image:
    registry: "mycompany.jfrog.io/docker-prod"
    tag: "5.2.42"
    pullPolicy: IfNotPresent
    pullSecrets:
      - name: jfrog-prod-creds

  postgres:
    enabled: true
    external: true
    host: "postgres.prod.svc.cluster.local"
    port: 5432
    database: "conductor"
    auth:
      existingSecret: "postgres-credentials"
      existingSecretPasswordKey: "postgres-password"
    ssl:
      enabled: true
      mode: "require"

  redis:
    enabled: true
    external: true
    host: "redis.prod.svc.cluster.local"
    port: 6379
    ssl: true
    auth:
      existingSecret: "redis-credentials"
      existingSecretPasswordKey: "redis-password"

  vault:
    enabled: true
    server:
      enabled: true
      role: "conductor-server-prod"
      envSecrets:
        POSTGRES_PASSWORD: "secret/data/conductor/prod/postgres#password"
        POSTGRES_USERNAME: "secret/data/conductor/prod/postgres#username"
        REDIS_PASSWORD: "secret/data/conductor/prod/redis#password"
        REDIS_LOCK_SERVER_PASSWORD: "secret/data/conductor/prod/redis#password"
        JWT_SECRET: "secret/data/conductor/prod/security#jwtSecret"
    workers:
      enabled: true
      role: "conductor-workers-prod"
      envSecrets:
        ACCESS_KEY_ID: "secret/data/conductor/prod/workers#keyId"
        ACCESS_KEY_SECRET: "secret/data/conductor/prod/workers#secret"

server:
  name: "conductor-server"
  replicas: 3
  image:
    repository: "orkes/conductor-server"
  resources:
    requests:
      cpu: "2"
      memory: "4Gi"
    limits:
      cpu: "4"
      memory: "8Gi"

workers:
  name: "conductor-workers"
  replicas: 2
  image:
    repository: "orkes/conductor-workers"
  resources:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "2"
      memory: "4Gi"

security:
  enabled: true
  defaultUserEmail: "admin@example.com"
  defaultUserName: "Admin"
```

**Result:**
- Server: `mycompany.jfrog.io/docker-prod/orkes/conductor-server:5.2.42`
- Workers: `mycompany.jfrog.io/docker-prod/orkes/conductor-workers:5.2.42`
- Credentials injected from Vault
- Image pulled using `jfrog-prod-creds` secret

## Troubleshooting

### ImagePullBackOff Error

If you see `ImagePullBackOff`:

1. **Verify image name:**
   ```bash
   helm template test . --values your-values.yaml | grep "image:"
   ```

2. **Check image exists in registry:**
   ```bash
   # For ACR
   az acr repository show-tags --name myacr --repository conductor-server

   # For GCR
   gcloud container images list-tags gcr.io/my-project/conductor-server

   # For ECR
   aws ecr describe-images --repository-name conductor-server
   ```

3. **Verify pull secret:**
   ```bash
   kubectl get secret my-registry-secret -o yaml
   ```

4. **Test pull secret:**
   ```bash
   kubectl create pod test-pull --image=myregistry.example.com/conductor-server:latest --overrides='{"spec":{"imagePullSecrets":[{"name":"my-registry-secret"}]}}'
   ```

### Wrong Image Name Generated

If the image name is incorrect:

1. **Check registry configuration:**
   ```bash
   helm template test . --values your-values.yaml --debug 2>&1 | grep "orkes-conductor.server.image.registry"
   ```

2. **Verify helper function logic:**
   - Registry from: `server.image.registry` → `global.image.registry` → empty
   - Repository from: `server.image.repository` → `image.repository`
   - Tag from: `server.image.tag` → `global.image.tag` → `Chart.AppVersion`

3. **Check for typos:**
   - Ensure `registry` not `registries`
   - Ensure proper YAML indentation

## Best Practices

### 1. Use Global Registry for Consistency

```yaml
global:
  image:
    registry: "myregistry.example.com"
    tag: "5.2.42"
```

This ensures both server and workers use the same registry.

### 2. Separate Registry for Development

```yaml
# values-dev.yaml
global:
  image:
    registry: "myregistry.example.com/dev"
    tag: "latest"
    pullPolicy: Always

# values-prod.yaml
global:
  image:
    registry: "myregistry.example.com/prod"
    tag: "5.2.42"
    pullPolicy: IfNotPresent
```

### 3. Use Specific Tags in Production

```yaml
# Don't use:
tag: "latest"  # ❌ Not recommended for production

# Use:
tag: "5.2.42"  # ✓ Specific version
tag: "sha256:abc123..."  # ✓ Digest for immutability
```

### 4. Configure Pull Secrets Properly

For production, prefer existing secrets managed externally:

```yaml
global:
  image:
    pullSecrets:
      - name: prod-registry-secret  # ✓ Managed externally
```

Avoid storing credentials in values.yaml:

```yaml
imageCredentials:
  password: "plaintext-password"  # ❌ Not recommended
```

### 5. Test Image Pull Before Deployment

```bash
# Create a test pod
kubectl run test-image \
  --image=myregistry.example.com/orkes/conductor-server:5.2.42 \
  --overrides='{"spec":{"imagePullSecrets":[{"name":"my-registry-secret"}]}}' \
  --rm -it --restart=Never

# If successful, the image can be pulled
```

## Registry-Specific Notes

### Docker Hub Rate Limits

When using DockerHub (default), you may hit rate limits. Solutions:

1. **Use authenticated pulls:**
   ```yaml
   imageCredentials:
     enabled: true
     username: "dockerhub-username"
     password: "dockerhub-token"
   ```

2. **Use a mirror or cache:**
   ```yaml
   global:
     image:
       registry: "dockerhub-mirror.example.com"
   ```

### Private Registry with Self-Signed Certificates

If your registry uses self-signed certificates, you may need to:

1. **Add CA certificate to trust store:**
   ```yaml
   trustStore:
     enabled: true
     jksFileName: "truststore.jks"
     jksFilePassword: "changeit"
   ```

2. **Configure container runtime** to trust the certificate (cluster-level)

### Registry Behind Corporate Proxy

If your Kubernetes cluster uses a proxy:

1. **Ensure proxy configuration in containerd/docker**
2. **Or use local registry mirror**
3. **Or configure Kubernetes to bypass proxy for registry**

## Validation Commands

### Check Generated Image Names

```bash
helm template test . --values your-values.yaml 2>&1 | \
  grep "image:" | \
  sed 's/.*image: "//' | sed 's/".*//'
```

### Verify All Components Use Custom Registry

```bash
helm template test . --values your-values.yaml 2>&1 | \
  grep "image:" | \
  grep -c "myregistry.example.com"
```

Should return 2 (server + workers).

### Check Image Pull Policy

```bash
helm template test . --values your-values.yaml 2>&1 | \
  grep "imagePullPolicy:"
```

## Summary

The Orkes Conductor Helm chart supports:

✅ **Global registry** configuration
✅ **Per-component registry** override
✅ **Full image names** with registry prefix
✅ **Multiple registry patterns**
✅ **All major cloud providers** (Azure, AWS, GCP)
✅ **Private registries** (JFrog, Harbor, etc.)
✅ **Flexible pull secret** management
✅ **Mixed public/private** images

Choose the pattern that best fits your infrastructure and security requirements!
