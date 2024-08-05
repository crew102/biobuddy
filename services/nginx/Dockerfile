FROM nginx:1.27.0

COPY install-cert.sh /nginx/install-cert.sh
COPY landing/ /www/landing

RUN apt-get update && \
    apt-get install -y certbot python3-certbot-nginx cron
