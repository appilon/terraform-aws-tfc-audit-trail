module "tfc-audit-trail-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "tfc-audit-trail"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}
