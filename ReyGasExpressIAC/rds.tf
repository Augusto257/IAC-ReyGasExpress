# Secrets Manager para almacenar la contraseña de la base de datos
resource "aws_secretsmanager_secret" "db_master_password" {
  name        = "reyGasExpress-db-master-password-${var.environment}-v9" 
  description = "Contraseña maestra para la instancia RDS de ReyGasExpress"

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Generar una contraseña aleatoria y almacenarla en Secrets Manager
resource "aws_secretsmanager_secret_version" "db_master_password_version" {
  secret_id     = aws_secretsmanager_secret.db_master_password.id
  secret_string = random_password.db_master_password_generated.result
}

# Recurso para generar una contraseña aleatoria
resource "random_password" "db_master_password_generated" {
  length         = 16
  special        = true
  override_special = "!#$%&*()-_=+[]{}<>:;?."
  min_lower      = 2
  min_upper      = 2
  min_numeric    = 2
  min_special    = 2
}


# Instancia RDS PostgreSQL
resource "aws_db_instance" "reygas_postgres_db" {
  identifier                = "${var.db_instance_identifier}-${var.environment}"
  engine                    = "postgres"
  engine_version            = var.db_engine_version
  instance_class            = var.db_instance_class
  allocated_storage         = var.db_allocated_storage
  storage_type              = "gp2" # General Purpose SSD
  multi_az                  = var.db_multi_az
  db_name                   = var.db_name
  username                  = var.db_username
  password                  = random_password.db_master_password_generated.result
  vpc_security_group_ids    = [aws_security_group.rds_sg.id]
  db_subnet_group_name      = aws_db_subnet_group.reygas_db_subnet_group.name
  skip_final_snapshot       = var.db_skip_final_snapshot
  publicly_accessible       = false
  port                      = 5432

  backup_retention_period = 7
  backup_window           = "03:00-05:00"

  performance_insights_enabled = true
  performance_insights_retention_period = 7

  tags = {
    Name        = "reygasexpress-postgres-db-${var.environment}"
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}