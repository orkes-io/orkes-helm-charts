## Usage

### Create a Secret With Image Pull Credentials

Use this command to create a pull secret compatible with this chart. It uses the default Docker Hub registry, username,
and email. Replace the password placeholder with the access token provided to you by the Orkes team.

```shell
kubectl create secret docker-registry orkes-registry \
  --namespace orkes-conductor \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=orkesdocker \
  --docker-password=<DOCKER_REGISTRY_TOKEN> \
  --docker-email=dockeracess@orkes.io
```

After creating the secret, set `image.repositorySecretName` in `values.yaml` to `orkes-registry` (default). If you
mirror images to a private unauthenticated registry, set `image.repositorySecretName` to an empty string to disable
`imagePullSecrets`.

### Secret Management Options

This chart supports two approaches for managing secrets:

1. **Traditional Kubernetes Secrets** (default) - Use Kubernetes secrets created manually or via tools
2. **HashiCorp Vault Integration** (optional) - Automatically inject secrets from Vault using the Vault Agent Injector

#### Using HashiCorp Vault for Secret Injection

To enable Vault secret injection, configure the `vault` section in your `values.yaml`:

```yaml
vault:
  enabled: true
  conductor:
    enabled: true
    role: "orkes-conductor"
    annotations:
      vault.hashicorp.com/agent-inject-secret-database: "secret/data/conductor/database"
      vault.hashicorp.com/agent-inject-template-database: |
        {{- with secret "secret/data/conductor/database" -}}
        export DB_HOST="{{ .Data.data.host }}"
        export DB_PASSWORD="{{ .Data.data.password }}"
        {{- end }}
  workers:
    enabled: true
    role: "orkes-workers"
    annotations:
      vault.hashicorp.com/agent-inject-secret-config: "secret/data/workers/config"
```

For more information on Vault annotations, see the [Vault Agent Injector documentation](https://developer.hashicorp.com/vault/docs/platform/k8s/injector/annotations).

### Install Orkes Conductor

Orkes Conductor loads its configuration from two properties files: `conductor.properties` and `workers.properties`. See
the "examples" folder for sample properties files.

```shell
helm install orkes-conductor orkesio/orkes-conductor --namespace orkes-conductor \
  --set-file conductor.properties=<PATH_TO_CONDUCTOR_PROPERTIES> \
  --set-file workers.properties=<PATH_TO_WORKER_PROPERTIES>
```

### Using with ArgoCD

ArgoCD supports Helm's `--set-file` functionality through the `fileParameters` field. Store your properties files in a Git repository alongside your ArgoCD Application manifest.

#### Directory Structure

```
your-gitops-repo/
├── argocd-applications/
│   └── orkes-conductor.yaml
└── config/
    ├── conductor.properties
    └── workers.properties
```

#### ArgoCD Application with fileParameters

Create your ArgoCD Application manifest using `fileParameters` to reference the properties files:

**Option 1: Install from Helm Chart Repository**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: orkes-conductor
  namespace: orkes-conductor
spec:
  project: default
  source:
    repoURL: https://orkes-io.github.io/orkes-helm-charts
    chart: orkes-conductor
    targetRevision: 3.0.0
    helm:
      # Use fileParameters to load properties files (equivalent to --set-file)
      fileParameters:
        - name: conductor.properties
          path: config/conductor.properties
        - name: workers.properties
          path: config/workers.properties
      # Optional: Override other values
      parameters:
        - name: image.repositorySecretName
          value: "orkes-registry"  # Use default, or set to your custom secret name
        - name: conductor.replicaCount
          value: "3"
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

**Option 2: Install from Git Branch**

To install directly from a Git branch (useful for testing or development):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: orkes-conductor
  namespace: orkes-conductor
spec:
  project: default
  source:
    repoURL: https://github.com/orkes-io/orkes-helm-charts.git
    targetRevision: haven/rework-tweaks  # Specify your branch name
    path: .  # Path to the chart in the repository
    helm:
      # Use fileParameters to load properties files (equivalent to --set-file)
      fileParameters:
        - name: conductor.properties
          path: config/conductor.properties
        - name: workers.properties
          path: config/workers.properties
      # Optional: Override other values
      parameters:
        - name: image.repositorySecretName
          value: "orkes-registry"  # Use default, or set to your custom secret name
        - name: conductor.replicaCount
          value: "3"
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

**Using Vault with ArgoCD:**

To enable Vault secret injection with ArgoCD, add Vault parameters to your Application:

```yaml
spec:
  source:
    helm:
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
              vault.hashicorp.com/agent-inject-secret-database: "secret/data/conductor/database"
              vault.hashicorp.com/agent-inject-template-database: |
                {{- with secret "secret/data/conductor/database" -}}
                export DB_HOST="{{ .Data.data.host }}"
                export DB_PASSWORD="{{ .Data.data.password }}"
                {{- end }}
```

For more details, see the [ArgoCD Application Specification Reference](https://argo-cd.readthedocs.io/en/latest/user-guide/application-specification/).