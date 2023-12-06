# How to deploy hashicorp vault on a kubernetes cluster

## Installing Helm
Initially, the installation of Helm is required, and the process for this is detailed in the "Installing [Helm](https://helm.sh/docs/intro/install/#from-apt-debianubuntu)" section:
```
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

## Setting up Vault in K8S

The majority of instructions can be found in the Vault on Kubernetes Deployment [Guide](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-raft-deployment-guide). To begin, the first step is to include the Helm repository.

Add the helm repository for hashicorp vault
```
helm repo add hashicorp https://helm.releases.hashicorp.com
```
The response should look similar to this:
```
"hashicorp" has been added to your repositories
```
Checkout the latest version of package:
```
helm search repo hashicorp/vault
```
The response should look similar to this:
```
NAME               CHART VERSION   APP VERSION     DESCRIPTION
hashicorp/vault    0.27.0          1.15.2          Official HashiCorp Vault Chart
```

## Configuration steps after installing Vault

Next, let's proceed with initializing the vault.
```
kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator init
```
The response should look similar to this:
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

Following that, we'll proceed to unseal the vault with the Unseal Key 1-5.
Unseal the vault with the Unseal Key 1
```
kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator unseal A2CnXAlnFigN0GPNsTiwSR4RucJ8vt0Q8FIxUYUzsCl0
```
The response should look similar to this:

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
Unseal the vault with the Unseal Key 2
```
kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator unseal oJrSB+1Vr4HA09H2tK4ysP76kzqDFEsjYvOurVhVBa3V
```
The response should look similar to this:
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
Unseal the vault with the Unseal Key 3
```
kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator unseal KSwubdHLgJ6prqEqKuvW/Zv8UaUQsDhXbZbNZ14/5EAQ
```
The response should look similar to this:
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
Unseal the vault with the Unseal Key 4
```
kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator unseal VM5ihi1YP1g47F1VXZN+aTG1cYHgEtA9wgOrNQU2sNKo
```
The response should look similar to this:
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
Unseal the vault with the Unseal Key 5
```
kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator unseal ie6wAguaNQQzLXmLhpLsq6bUXZITPi0X1VKMr1WgKZqP
```
The response should look similar to this:
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

Query the state of deploy and the pod should be in a READY state:
```
kubectl get pod -n vault
```
output
```
NAME                READY   STATUS    RESTARTS   AGE
vault-0             1/1     Running   0          5m
