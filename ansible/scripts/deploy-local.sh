#!/usr/bin/env bash
# Déploiement Ansible complet depuis le Mac.
# Usage : bash ansible/scripts/deploy-local.sh [--tags role1,role2]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ANSIBLE_DIR="${REPO_DIR}/ansible"
KEYS_DIR="${REPO_DIR}/keys"

# Fichier SSH config dans ~/.ssh/ — chemin SANS espaces, évite les bugs de quoting
SSH_CONFIG="${HOME}/.ssh/ansible_deploy_config"

# ── Couleurs ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}▶ $*${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $*${NC}"; }
die()   { echo -e "${RED}✗ $*${NC}"; exit 1; }

# ── Vérifications ─────────────────────────────────────────────────────────────
command -v terraform        &>/dev/null || die "terraform non trouvé"
command -v ansible-playbook &>/dev/null || die "ansible-playbook non trouvé (pip install ansible)"
command -v aws              &>/dev/null || die "aws CLI non trouvé"

# ── 1. Vault password ─────────────────────────────────────────────────────────
if [[ ! -f "${ANSIBLE_DIR}/.vault_pass" ]]; then
  warn ".vault_pass absent"
  read -rsp "Mot de passe Ansible Vault : " VAULT_PASS
  echo
  echo "${VAULT_PASS}" > "${ANSIBLE_DIR}/.vault_pass"
  chmod 600 "${ANSIBLE_DIR}/.vault_pass"
  info ".vault_pass créé"
fi

# ── 2. Clés SSH ───────────────────────────────────────────────────────────────
info "Récupération des clés SSH depuis Secrets Manager..."
mkdir -p "${KEYS_DIR}"

aws secretsmanager get-secret-value \
  --region eu-west-1 \
  --secret-id mathis/ssh/wordpress \
  --query SecretString --output text > "${KEYS_DIR}/wordpress.pem"

aws secretsmanager get-secret-value \
  --region eu-west-1 \
  --secret-id mathis/ssh/db \
  --query SecretString --output text > "${KEYS_DIR}/db.pem"

chmod 600 "${KEYS_DIR}/wordpress.pem" "${KEYS_DIR}/db.pem"
info "Clés SSH récupérées dans keys/"

# ── 3. IPs Terraform ──────────────────────────────────────────────────────────
info "Récupération des IPs depuis Terraform..."
cd "${REPO_DIR}"

WP_IP=$(terraform output -raw wordpress_public_ip 2>/dev/null)
DB_IP=$(terraform output -raw db_private_ip       2>/dev/null)

[[ -n "$WP_IP" ]] || die "wordpress_public_ip vide — terraform apply a-t-il tourné ?"
[[ -n "$DB_IP" ]] || die "db_private_ip vide — terraform apply a-t-il tourné ?"

info "WordPress : ${WP_IP}"
info "DB        : ${DB_IP}"

# ── 4. SSH config (chemin sans espaces → clés et ProxyJump) ───────────────────
# Le SSH config gère les clés et le ProxyJump, évitant tout problème de quoting
# lié aux espaces dans le chemin du projet.
info "Génération du SSH config..."
mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"

cat > "${SSH_CONFIG}" << EOF
Host ${WP_IP}
  User ec2-user
  IdentityFile "${KEYS_DIR}/wordpress.pem"
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ServerAliveInterval 30
  ServerAliveCountMax 10

Host ${DB_IP}
  User ec2-user
  IdentityFile "${KEYS_DIR}/db.pem"
  ProxyJump ec2-user@${WP_IP}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ServerAliveInterval 30
  ServerAliveCountMax 10
EOF

chmod 600 "${SSH_CONFIG}"
info "SSH config : ${SSH_CONFIG}"

# ── 5. host_vars ──────────────────────────────────────────────────────────────
info "Génération des host_vars..."
mkdir -p "${ANSIBLE_DIR}/host_vars"

cat > "${ANSIBLE_DIR}/host_vars/wp_host.yml" << EOF
ansible_host: ${WP_IP}
ansible_ssh_common_args: "-F ${SSH_CONFIG}"
EOF

cat > "${ANSIBLE_DIR}/host_vars/db_host.yml" << EOF
ansible_host: ${DB_IP}
ansible_ssh_common_args: "-F ${SSH_CONFIG}"
EOF

info "host_vars générés"

# ── 6. Test connectivité ──────────────────────────────────────────────────────
info "Test SSH WordPress (${WP_IP})..."
ssh -F "${SSH_CONFIG}" -o ConnectTimeout=5 ec2-user@"${WP_IP}" true \
  && info "WordPress OK" \
  || die "Impossible de joindre WordPress — vérifie l'IP et le SG"

info "Test SSH DB via ProxyJump (${DB_IP})..."
ssh -F "${SSH_CONFIG}" -o ConnectTimeout=10 ec2-user@"${DB_IP}" true \
  && info "DB OK" \
  || die "Impossible de joindre la DB via ProxyJump"

# ── 7. Ansible ────────────────────────────────────────────────────────────────
info "Lancement du playbook Ansible..."
cd "${ANSIBLE_DIR}"
ansible-playbook site.yml "$@"
