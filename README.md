# Home Assistant su Ubuntu Server

Installazione nuova: la casa è vuota, si configura dopo il primo avvio.
I container girano sul server; l'interfaccia si apre dal browser di un PC o del telefono sulla stessa rete (Ubuntu Server non ha desktop).

## Cosa fa GitHub

Il repo contiene solo lo stack Docker (compose, `.env.example`, YAML di partenza).
Utenti, integrazioni e automazioni nascono sul server e restano in `config/` (non su GitHub).

## Avvio sul server

Via SSH:

```bash
sudo apt update
sudo apt install -y git docker.io docker-compose-v2
sudo usermod -aG docker "$USER"
sudo systemctl enable --now docker
```

Esci e rientra in SSH, poi:

```bash
git clone https://github.com/edoxb/HomeAssistant.git ~/homeassistant
cd ~/homeassistant
cp .env.example .env
mkdir -p node-red config
sudo chown -R 1000:1000 node-red
docker compose up -d
```

Attendi che Home Assistant sia pronto:

```bash
docker compose logs -f homeassistant
```

Quando nei log compare che l'interfaccia è in ascolto, dal PC o dal telefono apri:

```text
http://IP_DEL_SERVER:8123
```

Lì fai l'onboarding: crea l'utente, imposta posizione/fuso orario, poi aggiungi dispositivi e automazioni. Tutto si salva da solo in `config/`.

## Microfono in Chrome (HTTPS con Caddy)

Chrome blocca il microfono su `http://`. Home Assistant resta in **HTTP sulla 8123** (così non perdi l'accesso). **Caddy** espone **HTTPS sulla 8443**.

```bash
cd ~/homeassistant
git pull
sudo ufw allow 8443/tcp comment 'HA HTTPS Caddy'
docker compose up -d
```

Dal PC apri **`https://IP_DEL_SERVER:8443`** (non 8123). Chrome: «Non sicuro» → Avanzate → procedi. Poi Assist → microfono.

`http://IP:8123` continua a funzionare, ma **senza microfono**. Per la voce usa sempre la 8443.

Su Android, se dopo «procedi» il mic resta rosso: Impostazioni → Sicurezza → installa certificato CA. Il file è `caddy/data/caddy/pki/authorities/local/root.crt` sul server.

L'app **Home Assistant** sul telefono può usare il microfono anche su `http://IP:8123`, senza Caddy.

Node-RED (opzionale, dopo HA):

```text
http://IP_DEL_SERVER:1880
```

In Node-RED il server Home Assistant è `http://127.0.0.1:8123`. Serve un Long-Lived Access Token dal profilo utente di HA.

## Firewall

```bash
sudo ufw allow OpenSSH
sudo ufw allow 8123/tcp comment 'Home Assistant'
sudo ufw enable
```

Non esporre 1880 su internet. Per l'editor Node-RED solo in LAN, adatta la subnet:

```bash
sudo ufw allow from 192.168.0.0/16 to any port 1880 proto tcp comment 'Node-RED LAN'
```

## Comandi utili

```bash
cd ~/homeassistant
docker compose logs -f
docker compose pull && docker compose up -d
docker compose down
```

`down` ferma i container e lascia i dati. Non cancellare `config/` se hai già configurato la casa.

## Backup

```bash
cd ~/homeassistant
docker compose down
tar -czf ~/homeassistant-backup.tgz .env config node-red
docker compose up -d
```

## Assist con Google Gemini

Ollama, Whisper e Piper non fanno parte dello stack. Il cervello e (se vuoi) voce usano l'API **Google Gemini** (piano free da AI Studio). La chiave resta in Home Assistant, non su GitHub.

1. Apri https://aistudio.google.com/ → account Google → **Get API key** / **Crea chiave API**.
2. In Home Assistant: Impostazioni → Dispositivi e servizi → Aggiungi → **Google Gemini** → incolla la chiave.
3. Crea un agente di conversazione Gemini e attiva **Controlla Home Assistant**.
4. Impostazioni → Assistenti vocali → **Pino**: agente Gemini; per la voce scegli STT/TTS Gemini (stessa integrazione).
5. Togli le integrazioni **Ollama** e **Wyoming** se le avevi aggiunte.

I limiti del piano free (richieste al giorno/minuto) sono in AI Studio. Le domande vanno a Google.

## Hardware

Home Assistant Container non include gli add-on. Zigbee, MQTT, ESPHome si aggiungono come altri servizi nello stesso Compose.
In `compose.yaml` c'è un volume D-Bus commentato se sul server usi Bluetooth.

## Prove su Windows

`network_mode: host` non funziona su Docker Desktop. Per un test locale:

```powershell
copy .env.example .env
docker compose -f compose.windows.yaml up -d
```

Poi `http://localhost:8123`. In Node-RED l'URL di HA è `http://homeassistant:8123`.
La configurazione vera resta quella del server.
