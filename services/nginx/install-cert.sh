#!/bin/bash

apt-get update && \
    apt-get install -y certbot python3-certbot-nginx cron

certbot --nginx \
  -d biobuddydev.com \
  -d www.biobuddydev.com \
  --non-interactive \
  --agree-tos \
  --email chriscrewbaker@gmail.com
