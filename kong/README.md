# AWS Onboarding API CMDB - Kong POC

## Start Kong

docker compose up -d

## Verify Kong

curl http://localhost:8001

## Test Current Route

curl http://localhost:8000/account_category

## Install decK

brew install deck

## Sync Configuration

./scripts/sync.sh

## Dump Kong Configuration

deck gateway dump \
  --kong-addr http://localhost:8001





`brew install kong/deck/deck`

```bash
# No GUI, no restarts of Kong required, just sync it.
deck gateway sync \
  --kong-addr http://localhost:8001 \
  kong.yaml
```

```bash
# Hitting cmdb_api's account_category:
curl http://localhost:8000/account_category
```