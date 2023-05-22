## VPC

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "${var.system_name}_${var.environment}_vpc"
  }
}

## Subnet(pub*2)

resource "aws_subnet" "public1" {
  availability_zone       = var.az_public1
  cidr_block              = var.cidr_public1
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.system_name}_${var.environment}_public1"
  }
}

resource "aws_subnet" "public2" {
  availability_zone       = var.az_public2
  cidr_block              = var.cidr_public2
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.system_name}_${var.environment}_public2"
  }
}

## Subnet(pri*2)

resource "aws_subnet" "private1" {
  availability_zone       = var.az_private1
  cidr_block              = var.cidr_private1
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.system_name}_${var.environment}_private1"
  }
}

resource "aws_subnet" "private2" {
  availability_zone       = var.az_private2
  cidr_block              = var.cidr_private2
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.system_name}_${var.environment}_private2"
  }
}

## InternetGateway

resource "aws_internet_gateway" "igw" {
  tags = {
    Name = "${var.system_name}_${var.environment}_igw"
  }
  vpc_id = aws_vpc.vpc.id
}

## Public Route

resource "aws_route_table" "rtb-public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.system_name}_${var.environment}_rtb-public"
  }
}

resource "aws_route" "public-route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.rtb-public.id
}

resource "aws_route_table_association" "pubsub1_routeassociation" {
  route_table_id = aws_route_table.rtb-public.id
  subnet_id      = aws_subnet.public1.id
}

resource "aws_route_table_association" "pubsub2_routeassociation" {
  route_table_id = aws_route_table.rtb-public.id
  subnet_id      = aws_subnet.public2.id
}

## Private Route
resource "aws_route_table" "rtb-private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.system_name}_${var.environment}_rtb-private"
  }
}

resource "aws_route_table_association" "prisub1_routeassociation" {
  route_table_id = aws_route_table.rtb-private.id
  subnet_id      = aws_subnet.private1.id
}

resource "aws_route_table_association" "prisub2_routeassociation" {
  route_table_id = aws_route_table.rtb-private.id
  subnet_id      = aws_subnet.private2.id
}

## VPC Endpoint SG
resource "aws_security_group" "endpoint_sg" {
  name   = "${var.system_name}_${var.environment}_endpoint-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_vpc]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.system_name}_${var.environment}_endpoint-sg"
  }
}

## for ECR

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.ap-northeast-1.ecr.dkr"
  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.endpoint_sg.id
  ]
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.ap-northeast-1.ecr.api"
  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.endpoint_sg.id
  ]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  route_table_ids = [
    aws_route_table.rtb-private.id
  ]
}

## for Cloudwatch Logs

resource "aws_vpc_endpoint" "logs" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.ap-northeast-1.logs"
  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.endpoint_sg.id
  ]
}

## for ECS EXEC

resource "aws_vpc_endpoint" "ssm" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.ap-northeast-1.ssm"
  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.endpoint_sg.id
  ]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.ap-northeast-1.ssmmessages"
  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.endpoint_sg.id
  ]
}