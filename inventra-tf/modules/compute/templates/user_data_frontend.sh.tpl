#!/bin/bash
set -euo pipefail
exec > /var/log/inventra-user-data.log 2>&1

yum update -y
yum install -y nginx git

# repo clone (frontend files)
cd /opt
rm -rf inventra
git clone https://github.com/zarcroft/inventra-flob.git 

# copie frontend (CORRIGÉ)
mkdir -p /usr/share/nginx/html
cp -r /opt/inventra-flob/inventra-tf/inventra/frontend/* /usr/share/nginx/html/

# patch API base URL (sécurisé)
#sed -i 's#<script src="app.js"></script>#<script>window.INVENTRA_API_URL = "http://${backend_private_ip}:5000";</script>\n<script src="app.js"></script>#' /usr/share/nginx/html/index.html

# nginx config
cat > /etc/nginx/conf.d/inventra.conf <<EOF
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://${backend_private_ip}:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /health {
        proxy_pass http://${backend_private_ip}:5000/health;
    }
}
EOF

# remove default nginx config
rm -f /etc/nginx/conf.d/default.conf || true

systemctl enable nginx
systemctl restart nginx