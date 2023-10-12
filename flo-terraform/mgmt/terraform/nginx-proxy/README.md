# LTE Tunnel Proxy

## Directions

```
terraform init .
terraform plan -var-files=lte-proxy.tfvars
terraform apply -var-files=lte-proxy.tfvars
```

OR

```
terraform init .
terraform plan \
    -var-file lte-proxy.tfvars \
    -out lte-proxy.tfout && \
    terraform apply lte-proxy.tfout
```
