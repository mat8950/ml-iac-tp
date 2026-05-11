locals {
  prefix = "mathis"

  name = {
    vpc     = "${local.prefix}-vpc-iac"
    igw     = "${local.prefix}-igw-iac"
    wp      = "${local.prefix}-wp-iac"
    db      = "${local.prefix}-db-iac"
    sg_wp   = "${local.prefix}-sg-wp-iac"
    sg_db   = "${local.prefix}-sg-db-iac"
    keypair = "${local.prefix}-keypair-iac"
  }
}
