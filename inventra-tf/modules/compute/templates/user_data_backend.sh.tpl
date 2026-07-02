#!/bin/bash
set -euo pipefail
exec > /var/log/inventra-user-data.log 2>&1

yum update -y
yum install -y python3 python3-pip awscli git

DB_URL=$(aws ssm get-parameter --name "${db_ssm_path}" \
  --with-decryption --query "Parameter.Value" --output text \
  --region ${aws_region})

cd /opt
git clone https://github.com/zarcroft/inventra-flob.git
cd /opt/inventra-flob/inventra-tf/inventra/backend

python3 -m pip install --upgrade pip
pip3 install -r requirements.txt

sudo mkdir -p /opt/inventra-flob/inventra-tf/instance
sudo chown -R ec2-user:ec2-user /opt/inventra-flob

sudo DATABASE_URL=$DB_URL python inventra/backend/seed.py

cat > /etc/systemd/system/inventra-backend.service << SERVICEEOF
[Unit]
Description=Inventra Backend API
After=network.target

[Service]
Environment="DATABASE_URL=$${DB_URL}"
Environment="PORT=5000"
WorkingDirectory=/opt/inventra-flob/inventra-tf/inventra/backend
ExecStart=/home/ec2-user/.local/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 app:app
Restart=always

[Install]
WantedBy=multi-user.target
SERVICEEOF


systemctl daemon-reload
systemctl enable --now inventra-backend