#!/usr/bin/env bash
# Запускать НА СЕРВЕРЕ (Ubuntu 22.04+) от root:
#   curl -fsSL ... | bash
# Или: scp deploy/server-bootstrap-ubuntu.sh root@IP:/root/ && ssh root@IP bash /root/server-bootstrap-ubuntu.sh
#
# Задаёт WEBROOT, ставит Nginx + PHP 8.1-FPM, создаёт vhost sheberkz.duckdns.org.
# MySQL и certbot — в конце подсказки.

set -euo pipefail

WEBROOT="${WEBROOT:-/var/www/sheber}"
DOMAIN="${DOMAIN:-sheberkz.duckdns.org}"
PHP_SOCK="${PHP_SOCK:-/var/run/php/php8.1-fpm.sock}"

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx php8.1-fpm php8.1-mysql php8.1-xml php8.1-mbstring php8.1-curl php8.1-gd php8.1-zip unzip

if [[ ! -e "$PHP_SOCK" ]]; then
  echo "WARN: $PHP_SOCK not found. List sockets:" >&2
  ls -la /var/run/php/ 2>/dev/null || true
  PHP_SOCK="$(ls /var/run/php/php*-fpm.sock 2>/dev/null | head -1 || true)"
  if [[ -z "$PHP_SOCK" ]]; then
    echo "ERROR: No php-fpm socket found. Install php8.1-fpm or set PHP_SOCK." >&2
    exit 1
  fi
  echo "Using PHP_SOCK=$PHP_SOCK"
fi

mkdir -p "$WEBROOT"/{uploads,storage/logs}
chown -R www-data:www-data "$WEBROOT"
chmod -R ug+rwX "$WEBROOT/uploads" "$WEBROOT/storage"

NGINX_SITE="/etc/nginx/sites-available/sheberkz"
cat >"$NGINX_SITE" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    root $WEBROOT;
    index index.php index.html;

    client_max_body_size 48M;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # snippets/fastcgi-php.conf даёт 404 для /api/ping.php (split_path_info без PATH_INFO)
    location ~ \\.php\$ {
        try_files \$uri =404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$uri;
        fastcgi_pass unix:$PHP_SOCK;
    }

    location ~* \\.(jpg|jpeg|png|gif|webp|ico|css|js|woff2?)\$ {
        expires 7d;
        add_header Cache-Control "public";
    }

    location ~ /\\. {
        deny all;
    }
}
EOF

ln -sf "$NGINX_SITE" /etc/nginx/sites-enabled/sheberkz
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

nginx -t
systemctl reload nginx
systemctl enable --now php8.1-fpm nginx

echo ""
echo "=== Bootstrap done ==="
echo "WEBROOT=$WEBROOT"
echo "1) Upload htdocs (from PC): .\\deploy\\sync-htdocs.ps1 -RemotePath \"$WEBROOT\""
echo "2) On server create: $WEBROOT/config.local.php (copy from config.local.example.php)"
echo "3) MySQL: CREATE DATABASE + user; import SQL if needed"
echo "4) HTTPS: apt install certbot python3-certbot-nginx && certbot --nginx -d $DOMAIN"
echo "5) Test: curl -sS http://$DOMAIN/api/ping.php"
