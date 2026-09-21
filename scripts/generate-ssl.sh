#!/usr/bin/env bash
# Genera un certificato TLS autofirmato per Home Assistant in LAN.
# Uso: ./scripts/generate-ssl.sh 192.168.1.10
set -euo pipefail

IP="${1:-}"
if [[ -z "$IP" ]]; then
  echo "Uso: $0 IP_DEL_SERVER"
  echo "Esempio: $0 192.168.1.50"
  echo "L'IP lo vedi con: hostname -I"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/config/ssl"
mkdir -p "$DIR"

openssl req -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
  -keyout "$DIR/privkey.pem" \
  -out "$DIR/fullchain.pem" \
  -subj "/CN=${IP}" \
  -addext "subjectAltName=IP:${IP},DNS:homeassistant.local"

chmod 600 "$DIR/privkey.pem"
echo "Creati:"
echo "  $DIR/fullchain.pem"
echo "  $DIR/privkey.pem"
echo
echo "Poi in config/configuration.yaml togli il commento al blocco http: e:"
echo "  docker compose restart homeassistant"
echo "Apri https://${IP}:8123 (non http)."
