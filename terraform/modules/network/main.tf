resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "VPN Gateway VPC"
  }
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.cidr_block, 4, 0)
  tags = {
    Name = "Private subnet"
  }
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "private_subnet_cidr" {
  value = aws_subnet.private.cidr_block
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.cidr_block, 4, 1)
  tags = {
    Name = "Public subnet"
  }
}

resource "aws_internet_gateway" "internetgw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "VPC IG"
  }
}

resource "aws_eip" "natgatewayip" {
}

resource "aws_nat_gateway" "natgateway" {
  allocation_id = aws_eip.natgatewayip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    "Name" = "NAT Gateway"
  }
}

output "nat_gateway_ip" {
  value = aws_eip.natgatewayip.public_ip
}

resource "aws_route_table" "routetableigw" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetgw.id
  }
  tags = {
    Name = "VPN Gateway route table"
  }
}

resource "aws_route_table_association" "publicassociation" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.routetableigw.id
}

resource "aws_route_table" "routetablengw" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgateway.id
  }
}

resource "aws_route_table_association" "privateassociation" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.routetablengw.id
}

#TO-DO: SUBNET SECURITY GROUPS