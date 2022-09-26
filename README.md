## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

  helm repo add <alias> https://orkes-io.github.io/orkes-helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo orkes-helm-charts` to see the charts.

### `orkes-conductor-standalone` chart

To install the `orkes-conductor-standalone` chart:

    helm install <name> orkes-helm-charts/orkes-conductor-standalone -n <namespace> --set imageCredentials.password=<image-pull-password>

To uninstall the chart:

    helm delete <name> -n <namespace>

To access the service after installation:
    
    kubectl --namespace <namespace> port-forward svc/<name>-orkes-conductor-standalone <LOCAL PORT>:5000

    Now you can access this on http://localhost:<LOCAL PORT>

:::tip
Wait for up to a minute for the server to load up. Lookup the pod status and pod logs to debug.
:::