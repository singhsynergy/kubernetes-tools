## 🧱 OVERVIEW (What We’ll Do)

1. Create a ClusterRole (read-only)
2. Bind role to a group
3. Generate client certificate for user
4. Create kubeconfig for user
5. User accesses cluster from their machine
6. Verify access

### 1️⃣ Create a ClusterRole (Read-Only for All Namespaces)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: devops-readonly
rules:
- apiGroups: ["", "apps", "batch", "autoscaling", "extensions", "networking.k8s.io"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
```

Apply:
```
kubectl apply -f devops-readonly.yaml
```
### 2️⃣ Bind ClusterRole to a GROUP

We will use a group name: devops-team
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: devops-readonly-binding
subjects:
- kind: Group
  name: devops-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: devops-readonly
  apiGroup: rbac.authorization.k8s.io
```

Apply:
```
kubectl apply -f devops-readonly-binding.yaml
```
### 3️⃣ Generate User Certificate (Admin Side)

Run this on Kubernetes control-plane / admin machine

🔹 Set variables
```
USER_NAME=jaswinder
GROUP_NAME=devops-team
```

🔹 Generate private key
```
openssl genrsa -out ${USER_NAME}.key 2048
```
🔹 Create CSR config
```
cat <<EOF > ${USER_NAME}.csr.conf
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[ dn ]
CN = ${USER_NAME}
O = ${GROUP_NAME}
EOF
```
🔹 Generate CSR
```
openssl req -new -key ${USER_NAME}.key \
  -out ${USER_NAME}.csr \
  -config ${USER_NAME}.csr.conf
```
🔹 Create Kubernetes CSR
```yaml
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USER_NAME}
spec:
  request: $(base64 -w0 ${USER_NAME}.csr)
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF
```
🔹 Approve CSR
```
kubectl certificate approve ${USER_NAME}
```
🔹 Extract certificate
```
kubectl get csr ${USER_NAME} \
  -o jsonpath='{.status.certificate}' | base64 -d > ${USER_NAME}.crt
```
### 4️⃣ Create Kubeconfig for User
🔹 Get cluster info
```
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_CERT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
```
🔹 Create kubeconfig
```
kubectl config --kubeconfig=${USER_NAME}-kubeconfig \
  set-cluster ${CLUSTER_NAME} \
  --server=${SERVER} \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true

kubectl config --kubeconfig=${USER_NAME}-kubeconfig \
  set-credentials ${USER_NAME} \
  --client-certificate=${USER_NAME}.crt \
  --client-key=${USER_NAME}.key \
  --embed-certs=true

kubectl config --kubeconfig=${USER_NAME}-kubeconfig \
  set-context ${USER_NAME}-context \
  --cluster=${CLUSTER_NAME} \
  --user=${USER_NAME}
```
```
kubectl config --kubeconfig=${USER_NAME}-kubeconfig \
  use-context ${USER_NAME}-context
```

### 5️⃣ Share Kubeconfig with User

Send only this file:

jaswinder-kubeconfig
