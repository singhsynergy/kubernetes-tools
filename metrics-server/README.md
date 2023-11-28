# How to Install Kubernetes (K8s) Metrics Server Step by Step on ubuntu

## Deploy_Metrics_server

Clone the repo and Goto Metrics_server folder with the below command:
```
git clone git@github.com:jassi-devops/kubernetes-tools.git
cd kubernetes-tools/metrics-server
```
Apply the Metrics_server manifest from the components.yaml file
```
kubectl apply -f metrics-server/components.yaml -n kube-system
```
Query the state of deploy:
```
kubectl get po -n kube-system | grep -i metrics
```
The response should look similar to this:
```
metrics-server-655d6d6565-xt8m5           1/1     Running   0             3m11s
```
Test Metrics Server Installation
```
kubectl top nodes
```
This command should display the resource utilization for each node in your cluster, including CPU and memory usage.
The response should look similar to this:
```
NAME      CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
master    230m         5%     3049Mi          38%
worker1   407m         5%     12642Mi         79%
worker2   131m         1%     5817Mi          36%
worker3   157m         1%     5638Mi          35%
```
To view pods resource utilization of your current namespace or specific namespace, run
```
kubectl top pod
kubectl top pod -n kube-system
```
