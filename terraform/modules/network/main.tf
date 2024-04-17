#TO-DO: SUBNET SECURITY GROUPS

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "VPN Gateway VPC"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.cidr_block, 4, 0)
  tags = {
    Name = "Private subnet"
  }
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