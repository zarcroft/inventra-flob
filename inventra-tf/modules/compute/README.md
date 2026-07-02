# module compute — à créer par les étudiants
#
# Ressources attendues :
#   - aws_instance "backend" :
#       • subnet  : public (pour accès Internet au pip install ; NAT Gateway non requis)
#       • ami     : Amazon Linux 2023
#       • user_data : installe Python, crée le venv, clone/copie l'app, démarre gunicorn
#         La variable DATABASE_URL est injectée depuis SSM Parameter Store via le user_data.
#   - aws_instance "frontend" :
#       • subnet  : public
#       • user_data : installe Nginx, déploie les fichiers statiques, configure le proxy_pass
#         vers l'IP privée du backend sur le port 5000
#   - aws_eip (optional) : IP publique fixe pour le frontend
#
# Variables d'entrée minimales :
#   name_prefix, ami_id, instance_type_frontend, instance_type_backend,
#   key_pair_name, subnet_id_frontend, subnet_id_backend,
#   sg_frontend_id, sg_backend_id, instance_profile_name,
#   db_ssm_path, db_name, db_username
#
# Outputs attendus :
#   frontend_public_ip, backend_private_ip, frontend_url

# ─── Exemple de user_data backend (à adapter) ──────────────────────
# #!/bin/bash
# set -euo pipefail
# yum update -y
# yum install -y python3-pip git
#
# # Récupérer l'URL de connexion depuis SSM
# DB_URL=$(aws ssm get-parameter --name "/inventra/db_url" \
#           --with-decryption --query "Parameter.Value" --output text \
#           --region eu-west-1)
#
# # Déployer l'application
# mkdir -p /opt/inventra
# cd /opt/inventra
# # Copier les fichiers applicatifs (S3, git clone, ou via remote-exec)
# pip3 install flask flask-cors flask-sqlalchemy psycopg2-binary gunicorn
#
# # Créer le service systemd
# cat > /etc/systemd/system/inventra-backend.service << EOF
# [Unit]
# Description=Inventra Backend API
# After=network.target
#
# [Service]
# Environment="DATABASE_URL=${DB_URL}"
# Environment="PORT=5000"
# WorkingDirectory=/opt/inventra
# ExecStart=/usr/local/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 app:app
# Restart=always
#
# [Install]
# WantedBy=multi-user.target
# EOF
#
# systemctl daemon-reload
# systemctl enable --now inventra-backend

# ─── Exemple de config Nginx frontend (à adapter) ──────────────────
# server {
#     listen 80;
#     root /usr/share/nginx/html;
#     index index.html;
#
#     # Servir le frontend statique
#     location / {
#         try_files $uri $uri/ /index.html;
#     }
#
#     # Proxy vers l'API backend
#     location /api/ {
#         proxy_pass http://<BACKEND_PRIVATE_IP>:5000;
#         proxy_set_header Host $host;
#         proxy_set_header X-Real-IP $remote_addr;
#     }
#
#     location /health {
#         proxy_pass http://<BACKEND_PRIVATE_IP>:5000/health;
#     }
# }
