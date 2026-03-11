#!/bin/bash
set -e

dnf install -y docker
systemctl enable docker
systemctl start docker

docker network create appnet

# PostgreSQL container
docker run -d \
  --name postgres \
  --network appnet \
  --restart unless-stopped \
  -e POSTGRES_DB=${db_name} \
  -e POSTGRES_USER=${db_user} \
  -e POSTGRES_PASSWORD=${db_password} \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16-alpine

# Wait for postgres to be ready
until docker exec postgres pg_isready -U ${db_user} -d ${db_name}; do
  echo "Waiting for postgres..."
  sleep 3
done

# Start app container
docker pull ${app_image}

docker run -d \
  --name devops_app \
  --network appnet \
  --restart unless-stopped \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e PORT=3000 \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=${db_name} \
  -e DB_USER=${db_user} \
  -e DB_PASSWORD=${db_password} \
  ${app_image}