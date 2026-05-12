#!/usr/bin/env bash
# Sauvegarde d'un site WordPress vers S3
# Usage : bash scripts/backup.sh <site_key>
#         bash scripts/backup.sh all          (tous les sites)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
die() { echo "✗ $*" >&2; exit 1; }

[[ $# -ge 1 ]] || die "Usage: $0 <site_key|all>"
TARGET="$1"

cd "${SCRIPT_DIR}"

if [[ "${TARGET}" == "all" ]]; then
  # Récupère la liste des sites depuis l'inventaire (noms d'hôtes du groupe webservers)
  SITES=$(ansible --list-hosts webservers --vault-password-file .vault_pass 2>/dev/null \
    | tail -n +2 | tr -d ' ')
  [[ -n "${SITES}" ]] || die "Aucun site trouvé dans le groupe webservers"
  for site in ${SITES}; do
    echo "▶ Backup de ${site}..."
    ansible-playbook playbooks/backup.yml \
      --vault-password-file .vault_pass \
      -e "site_key=${site}"
  done
else
  ansible-playbook playbooks/backup.yml \
    --vault-password-file .vault_pass \
    -e "site_key=${TARGET}"
fi

echo "✓ Backup(s) terminé(s)"
