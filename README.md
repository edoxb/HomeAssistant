# Home Assistant con Docker Compose

Configurazione minimale e portabile per eseguire Home Assistant Container con Docker Desktop su Windows e migrare poi su un host Linux.

## Prerequisiti

- Docker Desktop installato e avviato su Windows.
- Docker Engine e Docker Compose plugin quando migrerai su Linux.

## Struttura

- `compose.yaml`: definizione dei container Home Assistant e Node-RED.
- `.env`: parametri modificabili come porte, timezone e percorsi dati.
- `config/`: dati persistenti di Home Assistant, montati nel container come `/config`.
- `node-red/`: dati persistenti di Node-RED, montati nel container come `/data`.

## Avvio su Windows

Da PowerShell, nella cartella del progetto:

```powershell
docker compose up -d
```

Apri poi Home Assistant da:

```text
http://localhost:8123
```

Apri Node-RED da:

```text
http://localhost:1880
```

Per vedere i log:

```powershell
docker compose logs -f homeassistant
docker compose logs -f node-red
```

Per fermare il container senza cancellare i dati:

```powershell
docker compose down
```

## Aggiornamento

```powershell
docker compose pull
docker compose up -d
```

## Backup

Ferma Home Assistant prima di copiare i file, cosi' eviti database o configurazioni scritte a meta':

```powershell
docker compose down
tar -czf homeassistant-backup.tgz compose.yaml .env config node-red
docker compose up -d
```

Le cartelle piu' importanti sono `config/` per Home Assistant e `node-red/` per i flow e le impostazioni di Node-RED.

## Migrazione su Linux

Sul PC Windows:

```powershell
docker compose down
tar -czf homeassistant-migration.tgz compose.yaml .env config node-red
```

Copia `homeassistant-migration.tgz` sul PC Linux, poi estrailo in una directory dedicata:

```bash
mkdir -p ~/homeassistant
tar -xzf homeassistant-migration.tgz -C ~/homeassistant
cd ~/homeassistant
docker compose up -d
```

Su Linux, se Node-RED non riesce a scrivere nella cartella `node-red/`, assegna la cartella all'utente con UID 1000 usato dal container:

```bash
sudo chown -R 1000:1000 node-red
```

Se su Linux ti servira' una discovery di rete piu' affidabile, per esempio mDNS o UPnP, potrai valutare `network_mode: host` nel `compose.yaml`. In quel caso rimuovi la sezione `ports`, perche' con rete host non serve mappare la porta.

Esempio Linux con rete host:

```yaml
services:
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    restart: unless-stopped
    network_mode: host
    environment:
      TZ: ${TZ}
    volumes:
      - ${HA_CONFIG_DIR}:/config
```

## Servizi aggiuntivi

Home Assistant Container non include gli Add-on ufficiali. Se in futuro serviranno MQTT, Zigbee2MQTT, ESPHome, MariaDB o altri servizi, conviene aggiungerli come container separati nello stesso progetto Docker Compose.

## Collegamento Node-RED a Home Assistant

Dentro Node-RED installa, se non gia' presente, il pacchetto `node-red-contrib-home-assistant-websocket`.

Quando configuri il server Home Assistant in Node-RED usa:

```text
http://homeassistant:8123
```

Per l'autenticazione crea un Long-Lived Access Token dal profilo utente di Home Assistant e incollalo nella configurazione del server Node-RED.
