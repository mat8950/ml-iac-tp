#!/usr/bin/env bash
# Rotation des mots de passe d'un site WordPress
# Usage : bash scripts/rotate-passwords.sh <site_key>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AWS_REGION="${AWS_REGION:-eu-west-1}"
AWS_PREFIX="${AWS_PREFIX:-}"

die() { echo "✗ $*" >&2; exit 1; }

[[ $# -ge 1 ]] || die "Usage: $0 <site_key>"
SITE_KEY="$1"

# Récupère le préfixe depuis group_vars si non défini
if [[ -z "${AWS_PREFIX}" ]]; then
  AWS_PREFIX=$(grep 'aws_prefix:' "${SCRIPT_DIR}/group_vars/all.yml" 2>/dev/null \
    | awk '{print $2}' | tr -d '"') \
    || die "AWS_PREFIX non défini et group_vars/all.yml introuvable"
fi

echo "▶ Rotation des mots de passe pour le site : ${SITE_KEY}"

# Génère de nouveaux mots de passe
NEW_DB_PASS=$(openssl rand -base64 24 | tr -d '=+/\n' | head -c 20)
NEW_WP_PASS=$(openssl rand -base64 24 | tr -d '=+/\n' | head -c 20)

# Met à jour dans AWS Secrets Manager
echo "▶ Mise à jour dans Secrets Manager..."
aws secretsmanager update-secret \
  --region "${AWS_REGION}" \
  --secret-id "${AWS_PREFIX}/site/${SITE_KEY}/db-password" \
  --secret-string "${NEW_DB_PASS}"

aws secretsmanager update-secret \
  --region "${AWS_REGION}" \
  --secret-id "${AWS_PREFIX}/site/${SITE_KEY}/admin-password" \
  --secret-string "${NEW_WP_PASS}"

# Lance le playbook Ansible
echo "▶ Application des nouveaux mots de passe..."
cd "${SCRIPT_DIR}"
ansible-playbook playbooks/rotate-passwords.yml \
  --vault-password-file .vault_pass \
  -e "site_key=${SITE_KEY}" \
  -e "new_db_password=${NEW_DB_PASS}" \
  -e "new_admin_password=${NEW_WP_PASS}"

echo "✓ Mots de passe mis à jour pour ${SITE_KEY}"
echo "  DB password    → Secrets Manager : ${AWS_PREFIX}/site/${SITE_KEY}/db-password"
echo "  Admin password → Secrets Manager : ${AWS_PREFIX}/site/${SITE_KEY}/admin-password"
