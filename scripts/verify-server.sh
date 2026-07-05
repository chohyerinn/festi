#!/usr/bin/env bash
set -euo pipefail

echo "[1] hostname"
hostname

echo "[2] Apache"
apache2 -v || true
systemctl is-active apache2

echo "[3] Local health"
curl -fsS http://localhost/health.php

echo "[4] PHP syntax"
for file in \
  /var/www/html/index.php \
  /var/www/html/festivals.php \
  /var/www/html/festival_detail.php \
  /var/www/html/posts.php \
  /var/www/html/post_create.php \
  /var/www/html/post_detail.php \
  /var/www/html/mypage.php
do
  if [ -f "$file" ]; then
    php -l "$file"
  fi
done

echo "[5] DB connect"
php -r 'require "/var/www/html/config/db.php"; echo "PDO OK\n";'

echo "[6] Cloud DB port"
if [ -n "${DB_HOST:-}" ]; then
  nc -vz "$DB_HOST" 3306
else
  echo "skip: set DB_HOST to check the private Cloud DB port"
fi
