#!/usr/bin/env bash
# Génère et chiffre les host_vars à partir des outputs Terraform.
# À exécuter depuis le dossier ansible/ après chaque terraform apply.
set -euo pipefail

ANSIBLE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$(cd "${ANSIBLE_DIR}/.." && pwd)"

# ── Vérifications ─────────────────────────────────────────────────────────────
if [[ ! -f "${ANSIBLE_DIR}/.vault_pass" ]]; then
  echo "Erreur : fichier .vault_pass introuvable dans ansible/"
  echo "Crée-le d'abord : echo 'ton_mot_de_passe' > ansible/.vault_pass && chmod 600 ansible/.vault_pass"
  exit 1
fi

if ! command -v ansible-vault &>/dev/null; then
  echo "Erreur : ansible-vault n'est pas installé."
  exit 1
fi

# ── Récupération des IPs depuis Terraform ─────────────────────────────────────
echo "→ Récupération des outputs Terraform..."
WP_IP=$(cd "${TF_DIR}" && terraform output -raw wordpress_public_ip)
DB_IP=$(cd "${TF_DIR}" && terraform output -raw db_private_ip)

echo "  WordPress : ${WP_IP}"
echo "  DB        : ${DB_IP}"

# ── Génération des host_vars ──────────────────────────────────────────────────
mkdir -p "${ANSIBLE_DIR}/host_vars"

cat > "${ANSIBLE_DIR}/host_vars/wp_host.yml" << EOF
ansible_host: ${WP_IP}
ansible_ssh_private_key_file: keys/wordpress.pem
EOF

cat > "${ANSIBLE_DIR}/host_vars/db_host.yml" << EOF
ansible_host: ${DB_IP}
ansible_ssh_private_key_file: keys/db.pem
ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyJump='ec2-user@${WP_IP}'"
EOF

# ── Chiffrement avec Ansible Vault ────────────────────────────────────────────
echo "→ Chiffrement des host_vars..."
ansible-vault encrypt \
  --vault-password-file "${ANSIBLE_DIR}/.vault_pass" \
  "${ANSIBLE_DIR}/host_vars/wp_host.yml" \
  "${ANSIBLE_DIR}/host_vars/db_host.yml"

echo "✓ host_vars/wp_host.yml et host_vars/db_host.yml chiffrés avec succès."
echo "  Lance le playbook avec : ansible-playbook site.yml"
