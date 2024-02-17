# How to deploy ELK stack on a kubernetes with HELM
## Introduction
The ELK stack comprises Elasticsearch, Kibana, and Logstash. Its primary objective is to aggregate logs. The increasing prevalence of microservices architecture necessitates an enhanced method for aggregating and searching logs for debugging purposes. The ELK stack facilitates the aggregation and exploration of logs, with Elasticsearch, Kibana, and Logstash serving as its key components.

## Installing Helm
Initially, the installation of Helm is required, and the process for this is detailed in the "Installing [Helm](https://helm.sh/docs/intro/install/#from-apt-debianubuntu)" section:
```
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```
## Clonning Repo for ELK Setup
Clone the repo and Goto elk folder with the below command:
```
git clone https://github.com/jassi-devops/kubernetes-tools.git
cd kubernetes-tools/elk
```
## Setting up StorageAcoount
Establish a storage account for maintaining persistent logs. In this scenario, we are utilizing Azure Storage Account, but you can adapt the approach based on your specific environment.
create the storaeaccount with below command:
```
kubectl apply -f storageaccount/elastic-file-sc.yaml
```
## Setting up Elasticsearch
This database serves as the repository for storing all logs.
Before setting up Elasticsearch, it's necessary to modify the storage account name in the Elasticsearch YAML file. Update the **elk/elasticsearch/values.yaml** file by correcting the **storageClassName** specified on line 98.
```
storageClassName: elasticsearch-storage
```
Deploy Elasticsearch using the HELM command:
```
Helm install elasticsearch elasticsearch/.
```
## Setting up Logstash
Logstash functions as a data ingestion tool, collecting data (logs) from diverse sources, processing them, and subsequently forwarding the processed data to Elasticsearch.
Deploy Logstash using the kubectl command:
```
kubectl apply -f logstash/logstash.yaml
```
## Setting up Kibana
Kibana serves as the visualization platform, providing the capability to query Elasticsearch for data exploration and analysis.
Deploy kibana using the HELM command:
```
Helm install elasticsearch elasticsearch/.
```
## Testing
