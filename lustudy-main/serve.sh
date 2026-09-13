#!/bin/sh
# lustudy - Servidor local para terminal Android (Termux) y entornos Unix
# Uso: ./serve.sh [puerto]

PORT="${1:-8080}"
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1

echo "========================================"
echo "       lustudy · Servidor Local         "
echo "========================================"
echo "Directorio: $DIR"
echo "Puerto:     $PORT"
echo "----------------------------------------"

# Obtener dirección IP local si es posible
LOCAL_IP=""
if command -v ip >/dev/null 2>&1; then
  LOCAL_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
elif command -v ifconfig >/dev/null 2>&1; then
  LOCAL_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n1)
fi

echo "Acceso local:     http://localhost:$PORT"
[ -n "$LOCAL_IP" ] && echo "Acceso en red:    http://$LOCAL_IP:$PORT"
echo "----------------------------------------"
echo "Presiona Ctrl+C para detener el servidor."
echo ""

# Si estamos en Termux y tiene termux-open-url, abrir automáticamente en segundo plano
if command -v termux-open-url >/dev/null 2>&1; then
  (sleep 1 && termux-open-url "http://localhost:$PORT") &
elif command -v xdg-open >/dev/null 2>&1; then
  (sleep 1 && xdg-open "http://localhost:$PORT") >/dev/null 2>&1 &
fi

# Detectar e iniciar con la mejor opción disponible
if command -v python3 >/dev/null 2>&1; then
  echo "Iniciando con Python 3..."
  exec python3 -m http.server "$PORT" --bind 0.0.0.0
elif command -v python >/dev/null 2>&1; then
  echo "Iniciando con Python..."
  if python -c 'import sys; exit(0 if sys.version_info.major >= 3 else 1)' 2>/dev/null; then
    exec python -m http.server "$PORT" --bind 0.0.0.0
  else
    exec python -m SimpleHTTPServer "$PORT"
  fi
elif command -v php >/dev/null 2>&1; then
  echo "Iniciando con PHP..."
  exec php -S "0.0.0.0:$PORT"
elif command -v node >/dev/null 2>&1; then
  echo "Iniciando con Node.js..."
  exec node -e "
    const http = require('http');
    const fs = require('fs');
    const path = require('path');
    const mime = {
      '.html':'text/html', '.js':'application/javascript', '.css':'text/css',
      '.json':'application/json', '.webmanifest':'application/manifest+json',
      '.png':'image/png', '.svg':'image/svg+xml', '.ico':'image/x-icon'
    };
    http.createServer((req, res) => {
      let reqPath = decodeURI(req.url.split('?')[0]);
      if (reqPath === '/' || reqPath === '') reqPath = '/index.html';
      const fPath = path.join(process.cwd(), reqPath);
      fs.stat(fPath, (err, stats) => {
        if (err || !stats.isFile()) {
          res.writeHead(404, {'Content-Type':'text/plain'});
          res.end('404 Not Found');
          return;
        }
        const ext = path.extname(fPath).toLowerCase();
        res.writeHead(200, {'Content-Type': mime[ext] || 'application/octet-stream'});
        fs.createReadStream(fPath).pipe(res);
      });
    }).listen($PORT, '0.0.0.0', () => {
      console.log('Servidor Node.js activo en 0.0.0.0:$PORT');
    });
  "
elif command -v busybox >/dev/null 2>&1; then
  echo "Iniciando con BusyBox httpd..."
  exec busybox httpd -f -p "$PORT" -h "$DIR"
else
  echo "ERROR: No se encontró ningún intérprete adecuado (python3, python, php, node, busybox)."
  echo "Para instalar en Termux ejecuta: pkg install python"
  exit 1
fi
