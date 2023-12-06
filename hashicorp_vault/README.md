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
Clone the repo and Goto hashicorp_vault folder with the below command:
```
git clone git@github.com:jassi-devops/kubernetes-tools.git
cd kubernetes-tools/hashicorp_vault
```
Creating Storage Class and PVC to persist the data.
Since we're utilizing Azure File Storage, the following commands are tailored for Azure to create the Storage Class and PVC. If you're using a different storage system, feel free to bypass this step and create the Storage Class and PVC according to your specific storage requirements.

```
kubectl apply -f hashicorp_vault/volume/azure-file-sc.yaml -n vault
kubectl apply -f hashicorp_vault/volume/azure-file-pvc.yaml -n vault
```
Query the state of SC and PV:
```
kubectl get sc,pv -n vault | grep vault
```
The response should look similar to this:
```
storageclass.storage.k8s.io/vault-test-azurefile    file.csi.azure.com   Delete    Immediate    true       10m
persistentvolume/pvc-355faa3a-9fcd-4f84-a5b9-6343914d8e86   10Gi   RWX   Delete    Bound        default/vault-test-pvc vault-test-azurefile    12m
```
Modify the template/server-statefulset.yaml file and include the storageClassName attribute on line number 159.
```
storageClassName: vault-test-azurefile
```

Apply the Valut template(clusterrolebinding, configmap, headless-service, service, serviceaccount, statefulset) with below command:
```
kubectl apply -f templates/. -n vault-singlenode
```
The response should look similar to this:
```
clusterrolebinding.rbac.authorization.k8s.io/vault-server-binding configured
configmap/vault-config created
service/vault-internal created
service/vault created
serviceaccount/vault created
statefulset.apps/vault created
pod/vault-server-test created
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

Query the state of pod and it should be in a READY state:
```
kubectl get pod -n vault
```
The response should look similar to this:
```
NAME                READY   STATUS    RESTARTS   AGE
vault-0             1/1     Running   0          5m
```
## Configuring the Vault service with a domain

### Create the TLS secret
Ensure that the domain certificates are available on your server prior to executing the command below.
```
kubectl create secret tls vault-ssl --key private.key --cert cert.pem -n vault
```
Query the state of secret:
```
kubectl get secret  -n vault
```
The response should look similar to this:
```
NAME              TYPE                DATA   AGE
vault-ssl         kubernetes.io/tls   2      2m
```
Since we're relying on Ingress for domain connectivity, it's important to modify the ingress file to align the domain with your specific domain for a secure connection before executing the command below.
> NOTE: Ingress must be installed on your K8S cluster. If you're utilizing a Bare Metal K8S cluster, you can set up the Ingress with MetalLB using this [Guide](https://github.com/jassi-devops/kubernetes-tools/tree/main/ingress).

```
kubectl apply -f vault-ingress.yml -n vault
```
Query the state of ingress:
```
kubectl get ing -n vault
```
The response should look similar to this:
```
NAME            CLASS   HOSTS            ADDRESS        PORTS     AGE
vault-ingress   nginx   example.com      x.x.x.x        80, 443   2m
```

You can now access the Vault Service by navigating to the domain https://example.com. It will prompt for the root token, which you can find in the step where the vault was initialized.
$${\color{BLUE}You \space can.}$$
