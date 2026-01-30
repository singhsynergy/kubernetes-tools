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
  echo "Cloning Bitbucket repository..."
  git clone -b "$GIT_BRANCH" "$GIT_REPO" "$REPO_DIR"
fi

mkdir -p "$BACKUP_DIR"

### ---- STOP VAULT ----
systemctl stop vault

trap 'systemctl start vault' EXIT

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

echo "✅ Vault ${BACKUP_TYPE} backup completed successfully
