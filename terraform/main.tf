module "network" {
  source     = "./modules/network"
  cidr_block = var.cidr_block
}

module "vpn" {
  source = "./modules/vpn"
}