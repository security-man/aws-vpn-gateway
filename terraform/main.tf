module "network" {
  source     = "./modules/network"
  cidr_block = var.cidr_block
}

module "vpn" {
  source              = "./modules/vpn"
  vpc_id              = module.network.vpc_id
  private_subnet_id   = module.network.private_subnet_id
  private_subnet_cidr = module.network.private_subnet_cidr
}