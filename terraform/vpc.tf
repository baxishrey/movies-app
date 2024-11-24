data "aws_availability_zones" "available" {

}

resource "aws_vpc" "movies-app" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "${var.app_name}-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = length(slice(data.aws_availability_zones.available.names, 0, 2))
  vpc_id                  = aws_vpc.movies-app.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-subnet-public${count.index + 1}-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = length(slice(data.aws_availability_zones.available.names, 0, 2))
  vpc_id            = aws_vpc.movies-app.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}-subnet-private${count.index + 1}-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.movies-app.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

resource "aws_eip" "nat_gw" {
  depends_on = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "${var.app_name}-eip-${data.aws_availability_zones.available.names[0]}"
  }
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  allocation_id = aws_eip.nat_gw.id
  depends_on    = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = "${var.app_name}-nat-public1-${data.aws_availability_zones.available.names[0]}"
  }
}

resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.movies-app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  route {
    cidr_block = aws_vpc.movies-app.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "${var.app_name}-rtb-public"
  }
}

resource "aws_route_table_association" "public_rtb_association" {
  route_table_id = aws_route_table.public_rtb.id
  count          = length(aws_subnet.public_subnet)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
}

resource "aws_route_table" "private_rtb" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.movies-app.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  route {
    cidr_block = aws_vpc.movies-app.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "${var.app_name}-rtb-private${count.index + 1}-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_route_table_association" "private_rtb_association" {
  count          = length(aws_subnet.public_subnet)
  route_table_id = element(aws_route_table.private_rtb.*.id, count.index)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
}


resource "aws_security_group" "movies-app" {
  name   = var.security_group_name
  vpc_id = aws_vpc.movies-app.id

  tags = {
    Name = var.security_group_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.movies-app.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.movies-app.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "movies-app" {
  security_group_id = aws_security_group.movies-app.id
  ip_protocol       = "tcp"
  from_port         = 3000
  to_port           = 3000
  cidr_ipv4         = aws_vpc.movies-app.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "mongodb" {
  security_group_id = aws_security_group.movies-app.id
  ip_protocol       = "tcp"
  from_port         = 27017
  to_port           = 27017
  cidr_ipv4         = aws_vpc.movies-app.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "movies-app" {
  security_group_id = aws_security_group.movies-app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

}
