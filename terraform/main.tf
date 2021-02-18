module "network" {
  source          = "./modules/network"
  vpc_name        = var.vpc_name
  instance_count  = var.instance_count
  igw_name        = var.igw_name
  cidr            = var.cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

}

module "eks" {
  source          = "./modules/eks"
  private_subnets = module.network.private_subnets
  public_subnets = module.network.public_subnets
}
