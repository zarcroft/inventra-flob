# ─── AMI Amazon Linux 2023 la plus récente ──────────────────────────
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─── EC2 Backend Flask ────────────────────────────────────────────────
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type_backend
  subnet_id              = var.subnet_id_backend
  vpc_security_group_ids = [var.sg_backend_id]
  key_name               = var.key_pair_name
  iam_instance_profile   = var.instance_profile_name

  user_data = base64encode(templatefile("${path.module}/templates/user_data_backend.sh.tpl", {
    db_ssm_path = var.db_ssm_path
    aws_region  = var.aws_region
  }))

  tags = {
    Name = "${var.name_prefix}-backend"
  }
}

# ─── EC2 Frontend Nginx ────────────────────────────────────────────────
resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type_frontend
  subnet_id              = var.subnet_id_frontend
  vpc_security_group_ids = [var.sg_frontend_id]
  key_name               = var.key_pair_name

  user_data = base64encode(templatefile("${path.module}/templates/user_data_frontend.sh.tpl", {
    backend_private_ip = aws_instance.backend.private_ip
    index_html         = file(var.index_html_path)
    style_css          = file(var.style_css_path)
    app_js             = file(var.app_js_path)
  }))

  tags = {
    Name = "${var.name_prefix}-frontend"
  }
}

# ─── IP publique fixe pour le frontend (optionnel) ──────────────────
resource "aws_eip" "frontend" {
  count    = var.create_frontend_eip ? 1 : 0
  instance = aws_instance.frontend.id
  domain   = "vpc"

  tags = {
    Name = "${var.name_prefix}-frontend-eip"
  }
}
