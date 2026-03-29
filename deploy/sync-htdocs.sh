#!/usr/bin/env bash
# Синхронизация с Linux/macOS или WSL (rsync).
# Использование:
#   chmod +x deploy/sync-htdocs.sh
#   ./deploy/sync-htdocs.sh root@185.98.7.61 /var/www/sheber

set -euo pipefail
REMOTE="${1:?user@host}"
RDIR="${2:?/var/www/sheber}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Без --delete: на сервере не сотрутся лишние файлы в uploads/ и т.п.
rsync -avz \
  --exclude-from="$(dirname "$0")/rsync-exclude.txt" \
  "$ROOT/htdocs/" "${REMOTE}:${RDIR}/"

ssh "$REMOTE" "chown -R www-data:www-data '${RDIR}/uploads' '${RDIR}/storage' 2>/dev/null; chmod -R ug+rwX '${RDIR}/uploads' '${RDIR}/storage' 2>/dev/null || true"

echo "OK: curl -sS https://sheberkz.duckdns.org/api/ping.php"
