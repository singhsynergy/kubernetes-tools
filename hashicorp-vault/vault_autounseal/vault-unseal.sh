#!/bin/bash

export VAULT_ADDR="https://vault.com:8200"

# Wait until Vault API is reachable
until curl -s $VAULT_ADDR/v1/sys/health >/dev/null; do
  sleep 2
done

vault operator unseal 4Iu6WF95EZmIpUUD9IUTEwLZVms+7uL6soXs2
vault operator unseal iFyw0I8QfIRidy53U4J2CC1tyjcSbaec2+Lwr
vault operator unseal 5EKXWDO/+hjSErWhlSVLnyY2v0pnL2WwPJJ7W
