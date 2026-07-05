#!/bin/bash
dnf install -y nginx
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "unknown")

cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head><title>v1 - BLUE</title></head>
<body style="background:#1e3a8a;color:#fff;font-family:sans-serif;text-align:center;padding-top:15vh">
  <h1 style="font-size:4rem">BLUE</h1>
  <h2>Application version 1.0 (current production)</h2>
  <p>Served by instance: $INSTANCE_ID</p>
</body>
</html>
HTML

cat > /etc/nginx/nginx.conf <<'CONF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;
events { worker_connections 1024; }
http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  access_log /var/log/nginx/access.log;
  server {
    listen 80 default_server;
    root /usr/share/nginx/html;
    location / { index index.html; }
    location /health {
      default_type text/plain;
      return 200 'OK - blue v1';
    }
  }
}
CONF

systemctl enable nginx
systemctl restart nginx
