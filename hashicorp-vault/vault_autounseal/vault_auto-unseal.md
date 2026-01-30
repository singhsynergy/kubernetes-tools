
# Vault Auto-Unseal Using systemd

This guide configures **HashiCorp Vault** to automatically unseal itself after the Vault service starts, using a `systemd` `ExecStartPost` hook.

> ⚠️ **Security Warning**
> Storing unseal keys in plaintext on disk is **not recommended for production**.
> Consider using:
> - Auto-unseal with KMS (AWS KMS, Azure Key Vault, GCP KMS)
> - HSM
> - Vault Transit auto-unseal  
>
> Proceed only if you understand the risk.

---

## STEP 1: Create the Vault Unseal Script

Create a script that waits for Vault to become reachable and then runs the unseal commands.

### Create the script

```bash
sudo vi /usr/local/bin/vault-unseal.sh
````

### Script contents

```bash
#!/bin/bash

export VAULT_ADDR="https://vault.com:8200"

# Wait until Vault API is reachable
until curl -s $VAULT_ADDR/v1/sys/health >/dev/null; do
  sleep 2
done

vault operator unseal 4Iu6WF95EI1foKBYZmIpUUD9IUTEwLZVms+7uL6soXs2
vault operator unseal iFyw0I84vZzYuLdQfIRidy53U4J2CC1tycSbaec2+Lwr
vault operator unseal 5EKXWDO/+zmqv/uvz/SErWhlSVLnyY2v0pnL2WwPJJ7W
```

### Set permissions and ownership

```bash
sudo chmod 700 /usr/local/bin/vault-unseal.sh
sudo chown vault:vault /usr/local/bin/vault-unseal.sh
```

---

## STEP 2: Modify the Vault systemd Service

Update the existing Vault service to execute the unseal script after Vault starts.

### Edit the Vault service file

```bash
sudo vi /etc/systemd/system/multi-user.target.wants/vault.service
```

### Add the following line **directly under `ExecStart`**

```ini
ExecStartPost=/usr/local/bin/vault-unseal.sh
```

> ℹ️ `ExecStartPost` ensures the unseal script runs **after** the Vault process has started.

---

## STEP 3: Reload systemd and Restart Vault

Apply the changes and restart the Vault service.

```bash
sudo systemctl daemon-reload
sudo systemctl restart vault
```

---

## Verification (Optional)

Check Vault status to confirm it is unsealed:

```bash
vault status
```

Expected output:

* `Sealed: false`

---

## Summary

* Vault now automatically unseals on service start
* The unseal script waits for the Vault API before executing
* systemd handles execution order via `ExecStartPost`

---

✅ Setup complete

