# simple k8s

Boots a simple (insecure) Kubernetes cluster on DigitalOcean.

## Usage

Review variables in `provider.tf`

```sh
terraform apply
```

## Configure kubectl

```sh
kubectl config set-cluster <cluster-name> --server=http://master-ip/:8080
kubectl config set-context <context-name> --name <cluster-name>
kubectl use-conttext <context-name>
```
