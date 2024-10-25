provider "aws" {
    region = var.region
}

resource "aws_vpc" "vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

module "subnet" {
    source = "./modules/subnet"
    # variables can be hardcoded or referenced from the variables.tf file
    subnet_cidr_block = var.subnet_cidr_block
    subnet_avail_zone = var.subnet_avail_zone
    env_prefix = var.env_prefix
    vpc_id = aws_vpc.vpc.id
}

module "master-nodes" {
    source = "./modules/master-nodes"
    # variables can be hardcoded or referenced from the variables.tf file
    ip_addresses_range = var.ip_addresses_range
    image_name = var.image_name
    instance_type = var.instance_type
    subnet_id = module.subnet.subnet.id
    subnet_avail_zone = var.subnet_avail_zone
    env_prefix = var.env_prefix
    vpc_id = aws_vpc.vpc.id
    private_key_location = var.private_key_location
    key_name = var.key_name
}

module "worker-nodes" {
    source = "./modules/worker-nodes"
    # variables can be hardcoded or referenced from the variables.tf file
    ip_addresses_range = var.ip_addresses_range
    image_name = var.image_name
    instance_type = var.instance_type
    subnet_id = module.subnet.subnet.id
    subnet_avail_zone = var.subnet_avail_zone
    env_prefix = var.env_prefix
    vpc_id = aws_vpc.vpc.id
    private_key_location = var.private_key_location
    key_name = var.key_name
}
