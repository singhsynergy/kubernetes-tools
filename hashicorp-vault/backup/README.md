# Vault Backup Automation Script

This guide explains how to perform **daily, weekly, or monthly Vault backups**, store them in a Git repository, and enforce a retention policy.

> ⚠️ **Important Notes**
> - This script **stops Vault** during backup to ensure data consistency.
> - Backups include:
>   - Vault configuration directory
>   - Vault data directory
> - Ensure SSH access to the Git repository is properly configured.

## IMPORTANT NOTE

> 📝 **Change the following values as per your environment:**
> - `GIT_REPO`
> - `GIT_BRANCH`
> - `BASE_DIR`
> - `DATA_DIR`
> - `CONFIG_DIR`  
>
> Do **not** use the example values directly in production.

---

## Backup Types Supported

The script supports the following backup types:

| Type     | Retention Policy |
|---------|------------------|
| daily   | 7 days           |
| weekly  | 30 days          |
| monthly | 365 days         |

---

## STEP 1: Create the Vault Backup Script

### Create the script file

```bash
sudo vi /usr/local/bin/vault-backup.sh
````

### Script contents

```bash
#!/bin/bash
set -e

### ---- INPUT ----
BACKUP_TYPE=${1:?Usage: $0 (daily|weekly|monthly)}

case "$BACKUP_TYPE" in
  daily|weekly|monthly) ;;
  *)
    echo "Invalid backup type: $BACKUP_TYPE"
    exit 1
    ;;
esac

### ---- CONFIG ----
# Change these values as per your setup
GIT_REPO="git@bitbucket.org:abc.git"
GIT_BRANCH="backup"

BASE_DIR="/backup"
REPO_DIR="$BASE_DIR"
BACKUP_DIR="$REPO_DIR/vault-backups/$BACKUP_TYPE"

DATA_DIR="/var/lib/vault/data_new"
CONFIG_DIR="/etc/vault"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
HOSTNAME=$(hostname)

### ---- CLONE REPO IF NOT EXISTS ----
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Cloning Git repository..."
  git clone -b "$GIT_BRANCH" "$GIT_REPO" "$REPO_DIR"
fi

mkdir -p "$BACKUP_DIR"

### ---- STOP VAULT ----
systemctl stop vault

# Ensure Vault is restarted even if backup fails
trap 'systemctl start vault' EXIT

### ---- CREATE BACKUP ARCHIVE ----
ARCHIVE="$BACKUP_DIR/vault_${HOSTNAME}_${BACKUP_TYPE}_${TIMESTAMP}.tar.gz"
tar -czf "$ARCHIVE" "$CONFIG_DIR" "$DATA_DIR"

### ---- RETENTION POLICY (BEFORE COMMIT) ----
case "$BACKUP_TYPE" in
  daily)   find "$BACKUP_DIR" -type f -mtime +7 -delete ;;
  weekly)  find "$BACKUP_DIR" -type f -mtime +30 -delete ;;
  monthly) find "$BACKUP_DIR" -type f -mtime +365 -delete ;;
esac

### ---- GIT COMMIT & PUSH ----
cd "$REPO_DIR"
git add vault-backups/$BACKUP_TYPE
git commit -m "Vault ${BACKUP_TYPE} backup | ${HOSTNAME} | ${TIMESTAMP}" || echo "Nothing to commit"
git push origin "$GIT_BRANCH"

echo "✅ Vault ${BACKUP_TYPE} backup completed successfully"
```

---

## STEP 2: Set Permissions

```bash
sudo chmod 700 /usr/local/bin/vault-backup.sh
sudo chown root:root /usr/local/bin/vault-backup.sh
```

---

## STEP 3: Run the Backup Manually

```bash
sudo /usr/local/bin/vault-backup.sh daily
sudo /usr/local/bin/vault-backup.sh weekly
sudo /usr/local/bin/vault-backup.sh monthly
```

---

## (Optional) Automate with Cron

Example cron entries:

```bash
# Daily backup at 01:00
0 1 * * * /usr/local/bin/vault-backup.sh daily

# Weekly backup (Sunday) at 02:00
0 2 * * 0 /usr/local/bin/vault-backup.sh weekly

# Monthly backup (1st of month) at 03:00
0 3 1 * * /usr/local/bin/vault-backup.sh monthly
```

---

## Backup Structure

```text
vault-backups/
├── daily/
├── weekly/
└── monthly/
```

Backup file naming format:

```text
vault_<hostname>_<type>_<timestamp>.tar.gz
```

---

## Summary

* Supports daily, weekly, and monthly backups
* Stops Vault for consistent backups
* Enforces retention automatically
* Stores backups securely in a Git repository

---

✅ Vault backup setup complete


