# 🚀 Kafka 3-Node Cluster Setup (ZooKeeper-based, Domain Access)

This guide describes how to set up a **3-node Apache Kafka cluster** with:
- **3 Kafka brokers**
- **3 ZooKeeper nodes**
- **Domain-based access (no IPs exposed to clients)**

Compatible with:
- Kafka **2.8 / 3.0 / 3.1 / 3.6**
- Any Kafka version **still using ZooKeeper**

---

## 🖥️ Environment Assumptions

| Hostname               | IP Address        |
|------------------------|-------------------|
| kafka1.example.com     | 192.168.80.135    |
| kafka2.example.com     | 192.168.80.136    |
| kafka3.example.com     | 192.168.80.137    |

- 3 Linux VMs
- Ubuntu/Debian-based OS
- Passwordless SSH recommended

---

## ✅ 1. Install Java & Download Kafka

Run **on each VM**:

```bash
sudo apt update -y
sudo apt install -y openjdk-11-jdk wget

cd /opt
wget https://archive.apache.org/dist/kafka/3.6.0/kafka_2.13-3.6.0.tgz
tar -xvf kafka_2.13-3.6.0.tgz
mv kafka_2.13-3.6.0 kafka
````

---

## ✅ 2. Configure ZooKeeper (On ALL Nodes)

Edit:

```bash
/opt/kafka/config/zookeeper.properties
```

Use the **same file on all nodes**:

```properties
tickTime=2000
dataDir=/var/lib/zookeeper
clientPort=2181
initLimit=5
syncLimit=2

server.1=kafka1.example.com:2888:3888
server.2=kafka2.example.com:2888:3888
server.3=kafka3.example.com:2888:3888
```

### Create ZooKeeper Data Directory & myid

```bash
sudo mkdir -p /var/lib/zookeeper
```

Set **unique `myid` per node**:

```bash
# kafka1
echo 1 | sudo tee /var/lib/zookeeper/myid

# kafka2
echo 2 | sudo tee /var/lib/zookeeper/myid

# kafka3
echo 3 | sudo tee /var/lib/zookeeper/myid
```

---

## ✅ 3. Start ZooKeeper Cluster

```bash
/opt/kafka/bin/zookeeper-server-start.sh -daemon \
  /opt/kafka/config/zookeeper.properties
```

Verify:

```bash
netstat -tulnp | grep 2181
```

---

## ✅ 4. Configure Kafka Brokers

Edit on **each node**:

```bash
/opt/kafka/config/server.properties
```

---

### 🔹 Broker 1 (kafka1)

```properties
broker.id=1

listeners=INTERNAL://:9092,EXTERNAL://:9093
advertised.listeners=INTERNAL://kafka1.example.com:9092,EXTERNAL://kafka1.example.com:9093

listener.security.protocol.map=INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
inter.broker.listener.name=INTERNAL

zookeeper.connect=kafka1.example.com:2181,kafka2.example.com:2181,kafka3.example.com:2181
log.dirs=/var/lib/kafka
```

---

### 🔹 Broker 2 (kafka2)

```properties
broker.id=2

listeners=INTERNAL://:9092,EXTERNAL://:9093
advertised.listeners=INTERNAL://kafka2.example.com:9092,EXTERNAL://kafka2.example.com:9093

listener.security.protocol.map=INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
inter.broker.listener.name=INTERNAL

zookeeper.connect=kafka1.example.com:2181,kafka2.example.com:2181,kafka3.example.com:2181
log.dirs=/var/lib/kafka
```

---

### 🔹 Broker 3 (kafka3)

```properties
broker.id=3

listeners=INTERNAL://:9092,EXTERNAL://:9093
advertised.listeners=INTERNAL://kafka3.example.com:9092,EXTERNAL://kafka3.example.com:9093

listener.security.protocol.map=INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
inter.broker.listener.name=INTERNAL

zookeeper.connect=kafka1.example.com:2181,kafka2.example.com:2181,kafka3.example.com:2181
log.dirs=/var/lib/kafka
```

---

## 🔥 Why Two Listener Ports?

| Port | Purpose                               |
| ---: | ------------------------------------- |
| 9092 | Internal broker-to-broker traffic     |
| 9093 | External client access (domain-based) |

✔ Prevents metadata confusion
✔ Avoids split-brain & rebalancing issues
✔ Best practice for production clusters

---

## ✅ 5. Start Kafka Brokers

```bash
/opt/kafka/bin/kafka-server-start.sh -daemon \
  /opt/kafka/config/server.properties
```

Verify:

```bash
netstat -tulnp | grep 909
```

---

## ✅ 6. Validate Cluster Health

### List Brokers from ZooKeeper

```bash
/opt/kafka/bin/zookeeper-shell.sh kafka1.example.com:2181 <<< "ls /brokers/ids"
```

Expected output:

```text
[1, 2, 3]
```

---

### Create a Replicated Topic

```bash
/opt/kafka/bin/kafka-topics.sh \
  --create \
  --topic test-topic \
  --bootstrap-server kafka1.example.com:9093 \
  --replication-factor 3 \
  --partitions 3
```

---

## 🌐 7. (Optional) Expose Kafka via Single Domain Using NGINX

Example:

* `kafka.example.com:9094` → Kafka cluster

### NGINX TCP Stream Config

```nginx
stream {
    upstream kafka_cluster {
        server 192.168.80.135:9093;
        server 192.168.80.136:9093;
        server 192.168.80.137:9093;
    }

    server {
        listen 9094;
        proxy_pass kafka_cluster;
    }
}
```

Clients connect to:

```text
kafka.example.com:9094
```

⚠️ Note: Kafka still returns broker metadata — DNS must resolve broker hostnames.

---

## 🎯 Final Cluster Topology

### ZooKeeper Ensemble

```
kafka1.example.com:2181
kafka2.example.com:2181
kafka3.example.com:2181
```

### Kafka Brokers

```
kafka1.example.com:9092 (INTERNAL)
kafka1.example.com:9093 (EXTERNAL)

kafka2.example.com:9092 (INTERNAL)
kafka2.example.com:9093 (EXTERNAL)

kafka3.example.com:9092 (INTERNAL)
kafka3.example.com:9093 (EXTERNAL)
```

---

## ✅ Result

✔ Fully replicated
✔ High availability
✔ Domain-based access
✔ Production-safe Kafka + ZooKeeper cluster

---

