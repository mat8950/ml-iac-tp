#!/usr/bin/env bash
# Suppression propre d'un site WordPress
# Usage : bash scripts/destroy-site.sh <site_key>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
die() { echo "✗ $*" >&2; exit 1; }

[[ $# -ge 1 ]] || die "Usage: $0 <site_key>"
SITE_KEY="$1"

echo ""
echo "⚠  ATTENTION : suppression irréversible du site '${SITE_KEY}'"
echo ""
read -rp "Voulez-vous faire un backup avant ? [O/n] " do_backup
if [[ "${do_backup,,}" != "n" ]]; then
  echo "▶ Backup en cours..."
  bash "$(dirname "$0")/backup.sh" "${SITE_KEY}"
fi

cd "${SCRIPT_DIR}"
ansible-playbook playbooks/destroy-site.yml \
  --vault-password-file .vault_pass \
  -e "site_key=${SITE_KEY}"

echo ""
echo "✓ Site '${SITE_KEY}' supprimé."
echo ""
echo "Étape manuelle restante :"
echo "  1. Retirer '${SITE_KEY}' de la variable 'sites' dans Terraform/variables.tf (ou main.tf)"
echo "  2. Relancer : terraform apply (depuis le dossier Terraform)"
