resource "aws_vpc" "reygas_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "reygas-vpc-${var.environment}"
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}


# Subredes privadas para las Lambdas (ya existentes y bien configuradas)
resource "aws_subnet" "lambda_subnet_1" {
  vpc_id            = aws_vpc.reygas_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "lambda-subnet-1-${var.environment}"
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "lambda_subnet_2" {
  vpc_id            = aws_vpc.reygas_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "lambda-subnet-2-${var.environment}"
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Subredes privadas para RDS
resource "aws_subnet" "rds_subnet_1" {
  vpc_id            = aws_vpc.reygas_vpc.id
  cidr_block        = "10.0.10.0/24" # Nuevo CIDR para RDS
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "rds-subnet-1-${var.environment}"
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "rds_subnet_2" {
  vpc_id            = aws_vpc.reygas_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "rds-subnet-2-${var.environment}"
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Subnet Group para RDS (requerido para desplegar DB en subredes privadas)
resource "aws_db_subnet_group" "reygas_db_subnet_group" {
  name       = "reygas-db-subnet-group-${var.environment}"
  subnet_ids = [
    aws_subnet.rds_subnet_1.id,
    aws_subnet.rds_subnet_2.id
  ]
  description = "Subnet group for ReyGasExpress RDS PostgreSQL instance"

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "reygas_igw" {
  vpc_id = aws_vpc.reygas_vpc.id

  tags = {
    Name        = "reygas-igw-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.reygas_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "public-subnet-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name        = "reygas-nat-eip-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "reygas_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name        = "reygas-nat-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.reygas_igw]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.reygas_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.reygas_nat.id
  }

  tags = {
    Name = "private-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "lambda_subnet_1_rt" {
  subnet_id      = aws_subnet.lambda_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "lambda_subnet_2_rt" {
  subnet_id      = aws_subnet.lambda_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# Asociación de las nuevas subredes de RDS con la tabla de ruteo privada
resource "aws_route_table_association" "rds_subnet_1_rt" {
  subnet_id      = aws_subnet.rds_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "rds_subnet_2_rt" {
  subnet_id      = aws_subnet.rds_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group para las Lambdas (ya existente)
resource "aws_security_group" "lambda_sg" {
  name        = "reygas-lambda-sg-${var.environment}"
  description = "Security group for ReyGasExpress Lambda functions"
  vpc_id      = aws_vpc.reygas_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "reygas-lambda-sg-${var.environment}"
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# NUEVO Security Group para RDS PostgreSQL
resource "aws_security_group" "rds_sg" {
  name        = "reygas-rds-sg-${var.environment}"
  description = "Security group for ReyGasExpress RDS PostgreSQL database"
  vpc_id      = aws_vpc.reygas_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
    description     = "Allow PostgreSQL access from Lambda SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "reygas-rds-sg-${var.environment}"
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_endpoint" "cloudwatch_endpoint" {
  vpc_id              = aws_vpc.reygas_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"

  security_group_ids = [aws_security_group.lambda_sg.id]
  subnet_ids         = [aws_subnet.lambda_subnet_1.id, aws_subnet.lambda_subnet_2.id]

  private_dns_enabled = true

  tags = {
    Name = "cloudwatch-logs-endpoint-${var.environment}"
  }
}

# NUEVO VPC Endpoint para Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager_endpoint" {
  vpc_id              = aws_vpc.reygas_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"

  security_group_ids = [aws_security_group.lambda_sg.id]
  subnet_ids         = [aws_subnet.lambda_subnet_1.id, aws_subnet.lambda_subnet_2.id]

  private_dns_enabled = true

  tags = {
    Name = "secretsmanager-endpoint-${var.environment}"
  }
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.reygas_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Name = "s3-gateway-endpoint-${var.environment}"
  }
}