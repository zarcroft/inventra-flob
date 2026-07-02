# ─── SG frontend : seul groupe exposé à Internet ───────────────────
resource "aws_security_group" "frontend" {
  name        = "${var.name_prefix}-sg-frontend"
  description = "Allows public HTTP/HTTPS and restricted SSH"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Restricted SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "All outbound traffic allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg-frontend"
  }
}

# ─── SG backend : n'accepte que le frontend, pas Internet ──────────
resource "aws_security_group" "backend" {
  name        = "${var.name_prefix}-sg-backend"
  description = "Allows port 5000 only from frontend SG"
  vpc_id      = var.vpc_id

  ingress {
    description = "API access from frontend"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"

    security_groups = [aws_security_group.frontend.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg-backend"
  }
}

# ─── SG RDS : n'accepte que le backend, aucun accès public ─────────
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-sg-rds"
  description = "Allows port 5432 only from backend SG"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL access from backend only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    description = "All outbound traffic allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg-rds"
  }
}

# ─── Rôle IAM assumable par EC2 ─────────────────────────────────────
resource "aws_iam_role" "ec2_role" {
  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-ec2-role"
  }
}

# ─── Politique : lecture seule SSM Parameter Store + Secrets Manager
resource "aws_iam_role_policy" "ec2_read_secrets" {
  name = "${var.name_prefix}-ec2-read-secrets"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSSMParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/${var.name_prefix}/*"
      },
      {
        Sid    = "ReadSecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.name_prefix}/*"
      }
    ]
  })
}

# ─── Instance profile (obligatoire pour attacher un rôle à une EC2)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name_prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
