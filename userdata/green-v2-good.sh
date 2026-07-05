#!/bin/bash
dnf install -y nginx
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "unknown")

cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head><title>v2 - GREEN</title></head>
<body style="background:#065f46;color:#fff;font-family:sans-serif;text-align:center;padding-top:15vh">
  <h1 style="font-size:4rem">GREEN</h1>
  <h2>Application version 2.0 (new release)</h2>
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
      return 200 'OK - green v2';
    }
  }
}
CONF

systemctl enable nginx
systemctl restart nginx
