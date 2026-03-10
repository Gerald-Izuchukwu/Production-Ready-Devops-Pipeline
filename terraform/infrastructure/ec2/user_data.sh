#!/bin/bash
set -e

# Install Docker
dnf install -y docker
systemctl enable docker
systemctl start docker

# Pull and run the app container
docker pull ${app_image}

docker run -d \
  --name devops_app \
  --restart unless-stopped \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e DB_PASSWORD=${db_password} \
  ${app_image}