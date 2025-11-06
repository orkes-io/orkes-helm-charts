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

### Install Orkes Conductor

Orkes Conductor loads its configuration from two properties files: `conductor.properties` and `workers.properties`. See
the "examples" folder for sample properties files.

```shell
helm install orkes-conductor ../../ --namespace orkes-conductor \
  --set-file conductor.properties=<PATH_TO_CONDUCTOR_PROPERTIES> \
  --set-file workers.properties=<PATH_TO_WORKER_PROPERTIES>
```