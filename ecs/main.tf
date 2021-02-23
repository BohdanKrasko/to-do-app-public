module "network" {
  source          = "./modules/network"
  vpc_name        = var.vpc_name
  igw_name        = var.igw_name
  cidr            = var.cidr
  public_subnets  = var.public_subnets

}