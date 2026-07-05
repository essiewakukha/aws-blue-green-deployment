#!/bin/bash
dnf install -y nginx
cat > /etc/nginx/nginx.conf <<'CONF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;
events { worker_connections 1024; }
http {
  server {
    listen 80 default_server;
    location /health {
      default_type text/plain;
      return 200 'OK - green v2';
    }
    location / {
      return 500 'v2.1 broken release';
    }
  }
}
CONF
systemctl enable nginx
systemctl restart nginx
