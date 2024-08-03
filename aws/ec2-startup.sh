#!/bin/bash

set -e

apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    make \
    jq \
    unzip

echo -e "DOCKER INSTALL\n\n"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update && \
  apt-get install -y --no-install-recommends \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
#  python3 \
#  python3-pip \
#  python3-boto3

echo -e "AWS CLI INSTALL\n\n"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

echo -e "CLONING REPO\n\n"
cd /home
git clone https://github.com/crew102/biobuddy.git
cd biobuddy

echo -e "WRITING SECRETS FILE\n\n"
declare -a secret_names=(
  "PF_CLIENT_ID"
  "PF_CLIENT_SECRET"
  "OPENAI_API_KEY"
  "POLISHED_API_KEY"
  "FIREBASE_API_KEY"
  "RSTUDIO_PASSWORD"
)
for secret_name in "${secret_names[@]}"; do
  secret_value=$(
    aws secretsmanager get-secret-value --secret-id "$secret_name" \
      --query 'SecretString' --output text | \
      jq -r --arg KEY "$secret_name" \
      '. | to_entries | map(select(.key == $KEY)) | .[] | "\(.key)=\(.value)"'
  )
  echo "$secret_value" >> "secrets.txt"
done

# Set rstudio password using docker compose env vars interpolation
grep RSTUDIO_PASSWORD secrets.txt > .env

echo -e "BUILDING BB-APP IMAGE\n\n"
make img

echo -e "RUNNING DOCKER-COMPOSE UP\n\n"
make bup

# Not terribly proud of this. Dipping into the nginx container and installing
# an SSL cert without a real plan for how to renew.
echo -e "ONE-TIME INSTALL OF SSL CERT\n\n"
# Reminder: This is the version of the script that exists in the repo, not the
# one that you're dealing with during interactive deployment.
# Reminder: This script gets mapped into nginx container at docker compose up
local_version="services/nginx/install-cert.sh"
docker_version="/nginx/install-cert.sh"
chmod +x "$local_version"
nginx_container=$(docker compose ps -q nginx)
docker exec "$nginx_container" "$docker_version"

echo "cd /home/biobuddy" >> ~/.bashrc

echo -e "\n\nSTARTUP DONE\n\n"
