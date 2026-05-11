> Auteurs : Mathis LACEPPE,
> Alexandre CATHELIN,
> Nino SAPIN

## Architecture

![Architecture AWS](architecture.png)

## Structure des fichiers Terraform

| Fichier | Rôle |
|---|---|
| `terraform.tf` | Déclare les providers requis (AWS, TLS, HTTP, Random, Local) et le backend S3 pour le state distant |
| `providers.tf` | Configure le provider AWS : région `eu-west-1` et tags par défaut appliqués à toutes les ressources |
| `locals.tf` | Centralise la convention de nommage `mathis-<nom>-iac` pour toutes les ressources |
| `data.tf` | Datasources : AZs disponibles, AMI Amazon Linux 2023 la plus récente, IP publique via checkip.amazonaws.com |
| `network.tf` | VPC, Internet Gateway, sous-réseaux publics et privés (un par AZ), route tables publique et privée |
| `security_groups.tf` | Firewall WordPress (HTTP/HTTPS/SSH) et firewall DB (MySQL depuis WP + SSH), SSH restreint à l'IP publique |
| `keypair.tf` | Génère une clé RSA 4096 bits, la pousse dans AWS et sauvegarde le `.pem` localement |
| `instances.tf` | Instance WordPress via le module `modules/wordpress` (sous-réseau public) et instance DB (sous-réseau privé) |
| `s3.tf` | Bucket S3 pour les médias WordPress : accès public bloqué, versioning activé, chiffrement AES-256 |
| `secrets.tf` | Génère et stocke dans AWS Secrets Manager les mots de passe DB root et WordPress admin |
| `outputs.tf` | Expose les valeurs utiles : IP WordPress, IP DB, nom du bucket S3, ARNs des secrets |
| `main.tf` | Point d'entrée (vide, réservé pour extensions futures) |

### Module

| Fichier | Rôle |
|---|---|
| `modules/wordpress/main.tf` | Crée une instance EC2 t3.micro avec disque gp2 10GB |
| `modules/wordpress/variables.tf` | Variables du module : nom, prefix, AMI, subnet, security group, key pair |
| `modules/wordpress/outputs.tf` | Expose l'ID, l'IP publique et l'IP privée de l'instance |

### GitHub Actions

| Fichier | Rôle |
|---|---|
| `.github/workflows/terraform-plan.yml` | Sur chaque Pull Request : exécute `terraform plan` et poste le résultat en commentaire |
| `.github/workflows/terraform-apply.yml` | Sur chaque push sur `main` : exécute `terraform apply` automatiquement |
