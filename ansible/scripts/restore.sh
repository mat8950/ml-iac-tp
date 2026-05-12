#!/usr/bin/env bash
# Restauration d'un site WordPress depuis S3
# Usage : bash scripts/restore.sh <site_key> [backup_ts]
#         bash scripts/restore.sh site1                         (dernier backup)
#         bash scripts/restore.sh site1 20260512_143000         (backup spécifique)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AWS_REGION="${AWS_REGION:-eu-west-1}"
die() { echo "✗ $*" >&2; exit 1; }

[[ $# -ge 1 ]] || die "Usage: $0 <site_key> [backup_ts]"
SITE_KEY="$1"

cd "${SCRIPT_DIR}"

# Résolution du bucket S3 depuis l'inventaire
S3_BUCKET=$(ansible-inventory --vault-password-file .vault_pass --host "${SITE_KEY}" 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('s3_bucket',''))" 2>/dev/null) \
  || die "Impossible de récupérer le bucket S3 pour ${SITE_KEY}"
[[ -n "${S3_BUCKET}" ]] || die "s3_bucket non défini pour ${SITE_KEY}"

# Sélection du backup
if [[ $# -ge 2 ]]; then
  BACKUP_TS="$2"
else
  echo "▶ Recherche du dernier backup pour ${SITE_KEY}..."
  BACKUP_TS=$(aws s3 ls "s3://${S3_BUCKET}/backups/${SITE_KEY}/" \
    --region "${AWS_REGION}" 2>/dev/null \
    | awk '{print $2}' | tr -d '/' | sort | tail -1) \
    || die "Aucun backup trouvé pour ${SITE_KEY}"
  [[ -n "${BACKUP_TS}" ]] || die "Aucun backup trouvé dans s3://${S3_BUCKET}/backups/${SITE_KEY}/"
  echo "  Backup sélectionné : ${BACKUP_TS}"
fi

echo "▶ Restauration de ${SITE_KEY} depuis ${BACKUP_TS}..."
ansible-playbook playbooks/restore.yml \
  --vault-password-file .vault_pass \
  -e "site_key=${SITE_KEY}" \
  -e "backup_ts=${BACKUP_TS}"

echo "✓ Restauration terminée : ${SITE_KEY} @ ${BACKUP_TS}"
