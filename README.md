# kubernetes-tools

- [MetalLB](#MetalLB)
- [MetalLB](#Ingress)
## Deploy MetalLB
To install MetalLB, apply the manifest:
1. Create MetalLB namespace with command
```
kubectl create ns metallb-system
```
The response should look similar to this:
```
namespace/metallb-system created
```

2. Apply the MetalLB manifest controller and speaker from the metallb.yaml file:
```
kubectl apply -f metalLB/metallb.yaml -n metallb-system
```
The response should look similar to this:
```
podsecuritypolicy.policy/controller created
podsecuritypolicy.policy/speaker created
serviceaccount/controller created
serviceaccount/speaker created
clusterrole.rbac.authorization.k8s.io/metallb-system:controller created
clusterrole.rbac.authorization.k8s.io/metallb-system:speaker created
role.rbac.authorization.k8s.io/config-watcher created
role.rbac.authorization.k8s.io/pod-lister created
role.rbac.authorization.k8s.io/controller created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:controller created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:speaker created
rolebinding.rbac.authorization.k8s.io/config-watcher created
rolebinding.rbac.authorization.k8s.io/pod-lister created
rolebinding.rbac.authorization.k8s.io/controller created
daemonset.apps/speaker created
deployment.apps/controller created
```
3. Query the state of deploy:
```
kubectl get deploy -n metallb-system -o wide
```
The response should look similar to this:
```
NAME         READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                               SELECTOR
controller   0/1     1            0           11s   controller   quay.io/metallb/controller:v0.12.1   app=metallb,component=controller
```

This will deploy MetalLB to your cluster, under the **metallb-system** namespace. The components in the manifest are:

1. The **metallb-system/controller** deployment. This is the cluster-wide controller that handles IP address assignments.
2. The **metallb-system/speaker** daemonset. This is the component that speaks the protocol(s) of your choice to make the services reachable.
3. Service accounts for the controller and speaker, along with the RBAC permissions that the components need to function.

The installation manifest does not include a configuration file. MetalLB’s components will still start, but will remain idle until you define and deploy a **configmap**. The **memberlist** secret contains the **secretkey** to encrypt the communication between speakers for the fast dead node detection.

### Configure
Based on the planed network configuration, we will have a **metallb-config.yaml** as below:
```
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 13.234.15.110-13.234.15.112
```

> NOTE - You can change the IP pool according to your Network

1. Apply the MetalLB configmap from the metallb-config.yaml file:
```
kubectl apply -f metalLB/metallb-config.yaml -n metallb-system
```

2. Query the state of deploy
```
kubectl get deploy controller -n metallb-system -o wide
```
The response should look similar to this:
```
NAME         READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                               SELECTOR
controller   1/1     1            1           22s   controller   quay.io/metallb/controller:v0.12.1   app=metallb,component=controller
```

## Deploy Ingress
Apply the Ingress manifest from the ingress.yaml file
```
kubectl apply -f ingress/ingress.yaml -n ingress-nginx
```
Query the state of deploy:
```
kubectl get svc -n ingress-nginx
```
The response should look similar to this:
```
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.99.7.67      13.234.15.110    80:31884/TCP,443:30234/TCP   1m
ingress-nginx-controller-admission   ClusterIP      10.100.125.29   <none>        443/TCP                      1m
```
> Now if you look at the status on the EXTERNAL-IP it is 192.168.2.2 and can be access directly from external, without using NodePort or ClusterIp
