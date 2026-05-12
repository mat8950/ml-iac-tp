> **Auteurs** : Mathis LACEPPE · Alexandre CATHELIN · Nino SAPIN

## Architecture

![Architecture AWS](architecture.png)

## CI/CD

| Workflow | Déclencheur | Action |
|---|---|---|
| `terraform-plan.yml` | Pull Request | `terraform plan` + commentaire sur la PR |
| `terraform-apply.yml` | Push sur `main` | `terraform apply -auto-approve` |

## Récupérer les clés SSH

Les clés sont générées par Terraform et stockées dans AWS Secrets Manager.
Le dossier `keys/` est dans `.gitignore` — à créer une fois par poste de travail.

```bash
mkdir -p keys

# Clé WordPress
aws secretsmanager get-secret-value \
  --region eu-west-1 \
  --secret-id mathis/ssh/wordpress \
  --query SecretString --output text > keys/wordpress.pem
chmod 600 keys/wordpress.pem

# Clé DB
aws secretsmanager get-secret-value \
  --region eu-west-1 \
  --secret-id mathis/ssh/db \
  --query SecretString --output text > keys/db.pem
chmod 600 keys/db.pem
```

## Connexion aux instances

```bash
# WordPress (sous-réseau public)
ssh -i keys/wordpress.pem ec2-user@<wordpress_public_ip>

# DB (sous-réseau privé — via WordPress en bastion)
ssh -i keys/db.pem ec2-user@<db_private_ip>
```

> Les IPs sont disponibles après déploiement : `terraform output`

<!-- BEGIN_TF_DOCS -->
## Dépendances entre modules

```mermaid
graph BT
    subgraph L1["Couche 1 · Infrastructure de base"]
        direction LR
        network["module.network<br/>./modules/network"]
        s3["module.s3_media<br/>./modules/s3_bucket"]
    end

    subgraph L2["Couche 2 · Sécurité & Identité"]
        direction LR
        keypair_wp["module.keypair_wordpress<br/>./modules/keypair<br/>→ keys/mathis-keypair-wp-iac.pem"]
        keypair_db["module.keypair_db<br/>./modules/keypair<br/>→ keys/mathis-keypair-db-iac.pem"]
        secrets["module.secrets<br/>./modules/secrets"]
    end

    subgraph L3["Couche 3 · Application"]
        wordpress["module.wordpress<br/>./modules/wordpress"]
    end

    subgraph L4["Couche 4 · Données"]
        db["module.db<br/>./modules/database"]
    end

    wordpress -- "vpc_id / subnet_id" --> network
    wordpress -- key_name --> keypair_wp
    db -- "vpc_id / subnet_id" --> network
    db -- key_name --> keypair_db
    db -- sg_id --> wordpress
```
<!-- END_TF_DOCS -->
