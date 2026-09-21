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

## HTTPS locale (microfono in Chrome)

Chrome blocca il microfono su `http://`. Un certificato **autofirmato** può sbloccarlo dopo che accetti l'avviso (o installi il certificato sul dispositivo). Va bene in LAN, non esporlo su internet.

Sul server (sostituisci l'IP):

```bash
cd ~/homeassistant
git pull
chmod +x scripts/generate-ssl.sh
hostname -I
./scripts/generate-ssl.sh IP_DEL_SERVER
```

In `config/configuration.yaml` togli il commento alle tre righe `http:` / `ssl_certificate` / `ssl_key`. Poi:

```bash
docker compose restart homeassistant
```

Dal PC/telefono apri **`https://IP_DEL_SERVER:8123`** (non `http`). Chrome mostrerà un avviso: Avanzate → procedi al sito. Poi riprova il microfono in Assist.

Su Android, se dopo l'avviso il mic resta bloccato, Impostazioni → Sicurezza → Installa certificato (CA) e copia `config/ssl/fullchain.pem` sul telefono. Se l'IP del server cambia, rigenera il certificato con il nuovo IP.

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

## LLM e voce (Assist)

Lo stack include tre servizi extra, tutti in locale:

- **Ollama** (porta 11434): risponde alle domande e, se abilitato, controlla Home Assistant.
- **Whisper** (porta 10300): trasforma la voce in testo.
- **Piper** (porta 10200): legge le risposte ad alta voce, in italiano.

Non è ChatGPT in cloud: è un modello sul server (gratis, dati in casa). Per qualità tipo ChatGPT puoi dopo aggiungere l'integrazione **OpenAI** in Home Assistant con una API key a pagamento, al posto di Ollama o in parallelo.

Servono almeno **8 GB di RAM** (meglio 16). Senza GPU è lento ma usabile con modelli piccoli.

### Avvio

Dopo `git pull` e aver aggiornato `.env` da `.env.example`:

```bash
cd ~/homeassistant
mkdir -p ollama whisper piper
docker compose up -d
docker exec ollama ollama pull llama3.2
```

`llama3.2` è un modello piccolo (circa 2 GB). Il primo avvio di Whisper e Piper scarica i modelli: può richiedere qualche minuto.

### In Home Assistant

1. **Ollama:** Impostazioni → Dispositivi e servizi → Aggiungi → Ollama. URL `http://127.0.0.1:11434`, scegli `llama3.2`. Attiva **Controlla Home Assistant** così può accendere luci, ecc.
2. **Whisper:** Aggiungi → Wyoming Protocol → host `127.0.0.1`, porta `10300`.
3. **Piper:** Aggiungi → Wyoming Protocol → host `127.0.0.1`, porta `10200`.
4. **Pipeline:** Impostazioni → Assistenti vocali → Aggiungi. Lingua italiano, conversazione Ollama, STT Whisper, TTS Piper.

### Come usarlo

- Chat (tipo ChatGPT, in HA): icona Assist in alto a destra, scrivi.
- Voce dal telefono: app Companion → Assist, microfono.
- Voce dal browser: stessa icona Assist, microfono.

Il server Ubuntu non ha microfono: la voce parte dal telefono o dal PC. Un satellite (Home Assistant Voice, ESP32) si può aggiungere dopo.

Se Whisper/Piper restano grigi nella pipeline, la lingua deve essere **italiano** e coincidere con `WHISPER_LANGUAGE=it` e la voce `it_IT-...`. Poi ricarica le integrazioni Wyoming.

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
