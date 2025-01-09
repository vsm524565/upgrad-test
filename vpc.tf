resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "MainVPC"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "MainIGW"
  }
}
resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name = "NAT_EIP"
  }
}
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.private_a.id
  # Wait until the private subnet is created (though you may prefer a public subnet for NAT)
  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "MainNATGateway"
  }
}
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block             = var.private_subnet_a_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = false   # Private
  tags = {
    Name = "PrivateSubnetA"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block             = var.private_subnet_b_cidr
  availability_zone       = var.az_b
  map_public_ip_on_launch = false   # Private
  tags = {
    Name = "PrivateSubnetB"
  }
}
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block             = "10.0.3.0/24"
  availability_zone       = var.az_a  # e.g., "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnetA"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block             = "10.0.4.0/24"
  availability_zone       = var.az_b  # e.g., "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnetB"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "PrivateRouteTable"
  }
}

# Route for private subnets to go via NAT
resource "aws_route" "private_route_to_nat" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}
resource "aws_route_table_association" "private_rt_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route" "public_route_to_igw" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rt_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

