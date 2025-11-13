# Examples

## Evaluation
This example includes properties and commands to deploy Orkes Conductor along with its prerequisites for evaluation
purposes. It uses a standalone PostgreSQL database and Redis instance deployed via Helm charts. These configurations are
NOT production-ready and should only be used for evaluation.

## Security
This folder contains properties that can be added to a `conductor.properties` file to enhance security when deploying
Orkes Conductor in a production environment.

## Vault
This example demonstrates how to integrate HashiCorp Vault for dynamic secret injection into Orkes Conductor pods.
It includes:
- Example values file with Vault configuration
- Step-by-step setup instructions
- Vault policy and role configurations
- Troubleshooting guide

Use this approach to manage sensitive configuration like database passwords, API keys, and other secrets securely
without storing them in Git or Kubernetes secrets.