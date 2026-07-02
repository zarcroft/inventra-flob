#!/bin/bash
set -euo pipefail
exec > /var/log/inventra-user-data.log 2>&1

sudo yum update -y
sudo yum install -y python3 python3-pip awscli git

DB_URL=$(aws ssm get-parameter --name "${db_ssm_path}" \
  --with-decryption --query "Parameter.Value" --output text \
  --region ${aws_region})

cd /opt
git clone https://github.com/zarcroft/inventra-flob.git
cd /opt/inventra-flob/inventra-tf/inventra/backend

pip3 install -r requirements.txt

sudo mkdir -p /opt/inventra-flob/inventra-tf/instance
sudo chown -R ec2-user:ec2-user /opt/inventra-flob

sudo tee /etc/systemd/system/inventra-backend.service > /dev/null <<EOF
[Unit]
Description=Inventra Backend API
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/opt/inventra-flob/inventra-tf
Environment="DATABASE_URL=$DB_URL"
Environment="PYTHONPATH=/opt/inventra-flob/inventra-tf"
ExecStart=/home/ec2-user/.local/bin/gunicorn \
  --bind 0.0.0.0:5000 \
  --workers 2 \
  inventra.backend.app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload
sudo systemctl enable --now inventra-backend