

# App Gw

[Azure security baseline for Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/security-baseline)



# Development

First copy .env.secrets-TEMPLATE to .env.secrets and fill it in.

```sh
# deploy internal resources needed by customers deployments: ARG, ACR, AKV
make internal
# deploy multi-tenant resources: ARG, AVN (+ subnets), ASG, API, ADZ, ACI, AAG
make customers
# deploy specific tenante resouces: ACI, AMySQL
# claim subnet from AVN
# claim slot from AAG 
# add ACI to AAG Backend Pool
make customer
```

> NOTE: as its demo customers deployment here is only for 10 slots when 100 is limit dictated by one AAG limits.


# Usefull powershell

## Null coalescing

```ps1
PS /home/robert> $null ?? 100
100
```