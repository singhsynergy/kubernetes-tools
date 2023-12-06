# How to deploy hashicorp vault on a kubernetes cluster

## Prerequisites
- [Installing Helm](Install helm)
Setting up Vault
Installing Vault in K8S
Post Install Configuration of Vault
Creating a secret in vault


## Install helm

First we need to install helm, the setup is covered in Installing Helm(https://helm.sh/docs/intro/install/#from-apt-debianubuntu):
```
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

Setting up Vault
There are a bunch of steps, so let’s break them down into sections:

Installing Vault in K8S
Most instructions are available at Vault on Kubernetes Deployment Guide. First we need to add the helm repo:

> helm repo add hashicorp https://helm.releases.hashicorp.com
"hashicorp" has been added to your repositories
Then we can check out the latest version of package:

> helm search repo hashicorp/vault
NAME               CHART VERSION   APP VERSION     DESCRIPTION
hashicorp/vault    0.27.0          1.15.2          Official HashiCorp Vault Chart


Post Install Configuration of Vault
Now let’s initialze the vault:

kubectl exec --stdin=true --tty=true vault-0 -n vault-singlenode -- vault operator init

```
Unseal Key 1: A2CnXAlnFigN0GPNsTiwSR4RucJ8vt0Q8FIxUYUzsCl0
Unseal Key 2: oJrSB+1Vr4HA09H2tK4ysP76kzqDFEsjYvOurVhVBa3V
Unseal Key 3: KSwubdHLgJ6prqEqKuvW/Zv8UaUQsDhXbZbNZ14/5EAQ
Unseal Key 4: VM5ihi1YP1g47F1VXZN+aTG1cYHgEtA9wgOrNQU2sNKo
Unseal Key 5: ie6wAguaNQQzLXmLhpLsq6bUXZITPi0X1VKMr1WgKZqP

Initial Root Token: hvs.bCm2huSlAsFUeg4Fym75l8S1

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 3 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

Next we need to unseal the vault:

kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator unseal A2CnXAlnFigN0GPNsTiwSR4RucJ8vt0Q8FIxUYUzsCl0
```
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       b31d50f4-62a7-17e2-d30e-0425c9f0255b
Version            1.14.0
Build Date         2023-06-19T11:40:23Z
Storage Type       file
HA Enabled         false
```
kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator unseal oJrSB+1Vr4HA09H2tK4ysP76kzqDFEsjYvOurVhVBa3V
```
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    2/3
Unseal Nonce       b31d50f4-62a7-17e2-d30e-0425c9f0255b
Version            1.14.0
Build Date         2023-06-19T11:40:23Z
Storage Type       file
HA Enabled         false
```
kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator unseal KSwubdHLgJ6prqEqKuvW/Zv8UaUQsDhXbZbNZ14/5EAQ
```
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.14.0
Build Date      2023-06-19T11:40:23Z
Storage Type    file
Cluster Name    vault-cluster-3104ea48
Cluster ID      93432061-6e10-6f95-51d0-d2c7b0942f2b
HA Enabled      false
```

kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator unseal VM5ihi1YP1g47F1VXZN+aTG1cYHgEtA9wgOrNQU2sNKo
```
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.14.0
Build Date      2023-06-19T11:40:23Z
Storage Type    file
Cluster Name    vault-cluster-3104ea48
Cluster ID      93432061-6e10-6f95-51d0-d2c7b0942f2b
HA Enabled      false
```

kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator unseal ie6wAguaNQQzLXmLhpLsq6bUXZITPi0X1VKMr1WgKZqP
```
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.14.0
Build Date      2023-06-19T11:40:23Z
Storage Type    file
Cluster Name    vault-cluster-3104ea48
Cluster ID      93432061-6e10-6f95-51d0-d2c7b0942f2b
HA Enabled      false
```

After that all the pods should be in a READY state:
```
kubectl get pod -n vault-singlenode
```
output
```
NAME                READY   STATUS    RESTARTS   AGE
vault-0             1/1     Running   0          5m
