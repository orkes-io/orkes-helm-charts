This example includes properties and commands to deploy Orkes Conductor along with its prerequisites for evaluation
purposes. It uses a standalone PostgreSQL database and Redis instance deployed via Helm charts. These configurations are
NOT production-ready and should only be used for evaluation.

## Install Dependencies

### Add the Bitnami Helm repository:
```shell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
````

### Install Redis using Helm with the following command:
```shell
helm install orkes-conductor-redis bitnami/redis --namespace orkes-conductor --create-namespace \
  --set architecture=standalone \
  --set auth.enabled=false \
  --set master.resources.requests.memory=256Mi \
  --set master.resources.requests.cpu=200m \
  --set replica.resources.requests.memory=256Mi \
  --set replica.resources.requests.cpu=200m \
  --set master.persistence.enabled=false
```

### Install Postgres using Helm with the following command:
```shell
helm install orkes-conductor-postgres bitnami/postgresql --namespace orkes-conductor \
  --set auth.username=postgres \
  --set auth.password=postgres \
  --set primary.resources.requests.memory=256Mi \
  --set primary.resources.requests.cpu=200m \
  --set readReplicas.resources.requests.memory=256Mi \
  --set readReplicas.resources.requests.cpu=200m \
  --set primary.persistence.enabled=false \
  --set readReplicas.persistence.enabled=false
```

## Install Orkes Conductor
```shell
helm upgrade --install orkes-conductor ../../ --namespace orkes-conductor \
  --set conductor.replicaCount=1 \
  --set workers.replicaCount=1 \
  --set-file conductor.properties=conductor.properties \
  --set-file workers.properties=workers.properties
```

## Forward Ports to Access Orkes Conductor UI and API
```shell
kubectl port-forward -n orkes-conductor svc/orkes-conductor-server 8080:8080 5000:5000
```

## Get Pods
```shell
kubectl get pods -n orkes-conductor
```

## Get Logs for Orkes Conductor pod
```shell
kubectl logs -n orkes-conductor \
  -l app.kubernetes.io/name=orkes-conductor \
  -l app.kubernetes.io/component=app \
  --tail -1
```

## Get Logs for Orkes Workers pod
```shell
kubectl logs -n orkes-conductor \
  -l app.kubernetes.io/name=orkes-conductor \
  -l app.kubernetes.io/component=workers \
  --tail 500
```

## Uninstall Orkes Conductor
```shell
helm uninstall orkes-conductor --namespace orkes-conductor
```

## Uninstall Redis
```shell
helm uninstall orkes-conductor-redis --namespace orkes-conductor
```

## Uninstall Postgres
```shell
helm uninstall orkes-conductor-postgres --namespace orkes-conductor
```