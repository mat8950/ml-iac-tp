#!/usr/bin/env bash
# Déploiement complet IaC : Terraform (AWS) + Ansible (WordPress + PostgreSQL)
# Usage : bash deploy.sh [--skip-tf] [--skip-ansible] [--tags role1,role2]
#
# AVANT DE LANCER :
#   1. Remplir la section CONFIG ci-dessous
#   2. Renommer ce fichier : cp deploy.sh.changeme deploy.sh
#   3. Configurer vos credentials AWS : aws configure
#   4. S'assurer que ansible est installé : pip install ansible
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
#  CONFIGURATION — à remplir avant le premier lancement
# ═══════════════════════════════════════════════════════════════════════════════

# Préfixe unique pour toutes vos ressources AWS (votre prénom/alias, sans espaces)
PROJECT_PREFIX="CHANGEME"          # ex: alice, bob, john42

# Région AWS cible
AWS_REGION="eu-west-1"             # ex: eu-west-1, us-east-1, eu-central-1

# Votre IP publique autorisée à SSH (laisser vide pour auto-détecter)
MY_PUBLIC_IP=""                    # ex: "203.0.113.42/32" ou "203.0.113.0/24"

# IPs supplémentaires à autoriser en SSH (optionnel — une par ligne entre guillemets)
EXTRA_SSH_CIDRS=(
  # "1.2.3.4/32"    # Coéquipier 1
  # "5.6.7.8/32"    # Coéquipier 2
)

# Mot de passe Ansible Vault (laisser vide pour demander interactivement)
VAULT_PASS=""

# ═══════════════════════════════════════════════════════════════════════════════

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ANSIBLE_DIR="${REPO_DIR}/ansible"
KEYS_DIR="${REPO_DIR}/keys"
DOTENV="${REPO_DIR}/.deploy.env"
SSH_CONFIG="${HOME}/.ssh/ansible_deploy_config"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${GREEN}▶ $*${NC}"; }
section() { echo -e "\n${BLUE}══ $* ══${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $*${NC}"; }
die()     { echo -e "${RED}✗ $*${NC}"; exit 1; }

SKIP_TF=false
SKIP_ANSIBLE=false
ANSIBLE_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --skip-tf)      SKIP_TF=true ;;
    --skip-ansible) SKIP_ANSIBLE=true ;;
    *) ANSIBLE_ARGS+=("$arg") ;;
  esac
done

# ── Vérifications ─────────────────────────────────────────────────────────────
command -v terraform        &>/dev/null || die "terraform non trouvé"
command -v ansible-playbook &>/dev/null || die "ansible-playbook non trouvé (pip install ansible)"
command -v aws              &>/dev/null || die "aws CLI non trouvé"

[[ "${PROJECT_PREFIX}" == "CHANGEME" ]] && \
  die "Remplissez PROJECT_PREFIX dans la section CONFIG de ce script"

[[ "${PROJECT_PREFIX}" =~ ^[a-z0-9][a-z0-9-]{1,18}[a-z0-9]$ ]] || \
  die "PROJECT_PREFIX invalide : minuscules, chiffres et tirets uniquement (3-20 caractères)"

cd "${REPO_DIR}"

# ── Détection IP publique ──────────────────────────────────────────────────────
section "Détection de l'IP publique"
if [[ -z "${MY_PUBLIC_IP}" ]]; then
  MY_PUBLIC_IP="$(curl -sf --max-time 5 https://checkip.amazonaws.com)/32" \
    || die "Impossible de détecter votre IP publique — renseignez MY_PUBLIC_IP manuellement"
  info "IP détectée : ${MY_PUBLIC_IP}"
else
  info "IP configurée : ${MY_PUBLIC_IP}"
fi

# Construit la liste JSON des CIDRs pour Terraform
SSH_CIDRS_JSON="[\"${MY_PUBLIC_IP}\""
for cidr in "${EXTRA_SSH_CIDRS[@]+"${EXTRA_SSH_CIDRS[@]}"}"; do
  SSH_CIDRS_JSON+=", \"${cidr}\""
done
SSH_CIDRS_JSON+="]"

# ── Bucket S3 pour le state Terraform ─────────────────────────────────────────
section "Bucket S3 Terraform state"
if [[ -f "${DOTENV}" ]]; then
  # shellcheck source=/dev/null
  source "${DOTENV}"
  info "Bucket existant : ${TF_STATE_BUCKET}"
else
  # Génère un nom unique et crée le bucket
  SUFFIX="$(LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom 2>/dev/null | head -c 8 || \
            openssl rand -hex 4)"
  TF_STATE_BUCKET="${PROJECT_PREFIX}-tf-state-${SUFFIX}"

  info "Création du bucket S3 : ${TF_STATE_BUCKET}"
  if [[ "${AWS_REGION}" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "${TF_STATE_BUCKET}" \
      --region "${AWS_REGION}"
  else
    aws s3api create-bucket \
      --bucket "${TF_STATE_BUCKET}" \
      --region "${AWS_REGION}" \
      --create-bucket-configuration LocationConstraint="${AWS_REGION}"
  fi

  aws s3api put-bucket-versioning \
    --bucket "${TF_STATE_BUCKET}" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption \
    --bucket "${TF_STATE_BUCKET}" \
    --server-side-encryption-configuration \
      '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

  # Bloque l'accès public
  aws s3api put-public-access-block \
    --bucket "${TF_STATE_BUCKET}" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

  # Sauvegarde pour les prochains runs
  echo "TF_STATE_BUCKET=${TF_STATE_BUCKET}" > "${DOTENV}"
  info "Bucket créé et sauvegardé dans .deploy.env"
fi

# ── Terraform Init ─────────────────────────────────────────────────────────────
section "Terraform Init"
terraform init -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=${PROJECT_PREFIX}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="use_lockfile=true" \
  -backend-config="encrypt=true"

if [[ "${SKIP_TF}" == false ]]; then
  section "Terraform Apply"
  terraform apply -auto-approve \
    -var="prefix=${PROJECT_PREFIX}" \
    -var="aws_region=${AWS_REGION}" \
    -var="ssh_allowed_cidrs=${SSH_CIDRS_JSON}"
  info "Terraform apply terminé"
fi

# ── Récupération des IPs ───────────────────────────────────────────────────────
section "Récupération des outputs Terraform"
WP_IP=$(terraform output -raw wordpress_public_ip 2>/dev/null)
DB_IP=$(terraform output -raw db_private_ip       2>/dev/null)

[[ -n "${WP_IP}" ]] || die "wordpress_public_ip vide — relancez sans --skip-tf"
[[ -n "${DB_IP}" ]] || die "db_private_ip vide — relancez sans --skip-tf"

info "WordPress : ${WP_IP}"
info "DB        : ${DB_IP}"

# ── NAT Gateway ON ────────────────────────────────────────────────────────────
section "Activation du NAT Gateway"
terraform apply -auto-approve \
  -var="prefix=${PROJECT_PREFIX}" \
  -var="aws_region=${AWS_REGION}" \
  -var="ssh_allowed_cidrs=${SSH_CIDRS_JSON}" \
  -var="enable_nat_gateway=true"
info "NAT Gateway activé — la DB a accès à internet"

disable_nat() {
  section "Désactivation du NAT Gateway"
  cd "${REPO_DIR}"
  if terraform apply -auto-approve \
      -var="prefix=${PROJECT_PREFIX}" \
      -var="aws_region=${AWS_REGION}" \
      -var="ssh_allowed_cidrs=${SSH_CIDRS_JSON}" \
      -var="enable_nat_gateway=false" 2>&1; then
    info "NAT Gateway désactivé"
  else
    warn "Terraform apply échoué — nettoyage manuel..."
    terraform state rm "module.network.aws_nat_gateway.this[0]" 2>/dev/null || true
    terraform state rm "module.network.aws_eip.nat[0]"          2>/dev/null || true
    ALLOC_ID=$(aws ec2 describe-addresses --region "${AWS_REGION}" \
      --filters "Name=tag:Name,Values=${PROJECT_PREFIX}-nat-eip" \
      --query 'Addresses[0].AllocationId' --output text 2>/dev/null || true)
    if [[ -n "${ALLOC_ID}" && "${ALLOC_ID}" != "None" ]]; then
      aws ec2 release-address --region "${AWS_REGION}" --allocation-id "${ALLOC_ID}" \
        && info "EIP libéré" || warn "Impossible de libérer l'EIP manuellement"
    fi
    info "State nettoyé"
  fi
}
trap disable_nat EXIT

if [[ "${SKIP_ANSIBLE}" == true ]]; then
  info "--skip-ansible : fin du script (NAT sera désactivé)"
  exit 0
fi

# ── Vault password ─────────────────────────────────────────────────────────────
section "Configuration Ansible Vault"
if [[ -n "${VAULT_PASS}" ]]; then
  echo "${VAULT_PASS}" > "${ANSIBLE_DIR}/.vault_pass"
  chmod 600 "${ANSIBLE_DIR}/.vault_pass"
  info ".vault_pass créé depuis la variable VAULT_PASS"
elif [[ ! -f "${ANSIBLE_DIR}/.vault_pass" ]]; then
  warn ".vault_pass absent"
  read -rsp "Mot de passe Ansible Vault : " _vp; echo
  echo "${_vp}" > "${ANSIBLE_DIR}/.vault_pass"
  chmod 600 "${ANSIBLE_DIR}/.vault_pass"
  unset _vp
  info ".vault_pass créé"
fi

# ── Clés SSH ───────────────────────────────────────────────────────────────────
section "Clés SSH (depuis AWS Secrets Manager)"
mkdir -p "${KEYS_DIR}"
aws secretsmanager get-secret-value --region "${AWS_REGION}" \
  --secret-id "${PROJECT_PREFIX}/ssh/wordpress" \
  --query SecretString --output text > "${KEYS_DIR}/wordpress.pem"
aws secretsmanager get-secret-value --region "${AWS_REGION}" \
  --secret-id "${PROJECT_PREFIX}/ssh/db" \
  --query SecretString --output text > "${KEYS_DIR}/db.pem"
chmod 600 "${KEYS_DIR}/wordpress.pem" "${KEYS_DIR}/db.pem"
info "Clés récupérées dans keys/"

# ── SSH config ─────────────────────────────────────────────────────────────────
section "SSH config"
mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
cat > "${SSH_CONFIG}" << EOF
Host ${WP_IP}
  User ec2-user
  IdentityFile ${KEYS_DIR}/wordpress.pem
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ServerAliveInterval 30
  ServerAliveCountMax 10

Host ${DB_IP}
  User ec2-user
  IdentityFile ${KEYS_DIR}/db.pem
  ProxyJump ec2-user@${WP_IP}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ServerAliveInterval 30
  ServerAliveCountMax 10
EOF
chmod 600 "${SSH_CONFIG}"

# ── host_vars ──────────────────────────────────────────────────────────────────
section "Génération des host_vars et group_vars"
mkdir -p "${ANSIBLE_DIR}/host_vars"
cat > "${ANSIBLE_DIR}/host_vars/wp_host.yml" << EOF
ansible_host: ${WP_IP}
ansible_ssh_common_args: "-F ${SSH_CONFIG}"
EOF
cat > "${ANSIBLE_DIR}/host_vars/db_host.yml" << EOF
ansible_host: ${DB_IP}
ansible_ssh_common_args: "-F ${SSH_CONFIG}"
EOF

# Met à jour group_vars/all.yml avec la région et le préfixe courants
cat > "${ANSIBLE_DIR}/group_vars/all.yml" << EOF
aws_region: ${AWS_REGION}
aws_prefix: ${PROJECT_PREFIX}
EOF
info "host_vars et group_vars générés"

# ── Test connectivité ──────────────────────────────────────────────────────────
section "Test connectivité SSH"
ssh -F "${SSH_CONFIG}" -o ConnectTimeout=10 ec2-user@"${WP_IP}" true \
  && info "WordPress OK" || die "WordPress injoignable"
ssh -F "${SSH_CONFIG}" -o ConnectTimeout=15 ec2-user@"${DB_IP}" true \
  && info "DB OK"        || die "DB injoignable via ProxyJump"

# ── Ansible ───────────────────────────────────────────────────────────────────
section "Ansible Playbook"
cd "${ANSIBLE_DIR}"
ansible-playbook site.yml "${ANSIBLE_ARGS[@]+"${ANSIBLE_ARGS[@]}"}"

info "Déploiement terminé — WordPress : http://${WP_IP}/wp-admin/install.php"
