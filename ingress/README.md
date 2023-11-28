# How to Install and setup Ingress on Kubernetes (K8s) Step by Step on ubuntu

## prerequisite

Setup MetalLB if you are not going to use any third party LoadBalancer service
- [Setup MetalLB](https://github.com/jassi-devops/kubernetes-tools/tree/main/metalLB)

## Setup Ingress
Clone the repo and Goto ingress folder with the below command:
```
git clone git@github.com:jassi-devops/kubernetes-tools.git
cd kubernetes-tools/ingress
```
Apply the Ingress manifest from the ingress.yaml file
```
kubectl apply -f ingress.yaml -n ingress-nginx
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
