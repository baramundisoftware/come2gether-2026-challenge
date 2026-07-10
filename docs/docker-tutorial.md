# Docker in 10 Minuten — für Einsteiger

Diese Challenge läuft komplett in **Docker**. Du musst Docker nicht beherrschen —
diese Seite erklärt genau so viel, wie du für die Challenge brauchst. Wenn du
Docker schon kennst, kannst du direkt zum [Quick Start](../README.md#quick-start)
springen.

---

## Was ist Docker (und warum)?

Docker verpackt eine Anwendung samt allem, was sie zum Laufen braucht
(Betriebssystem-Bibliotheken, Node.js, Konfiguration), in ein **Image**. Aus
einem Image startet Docker einen **Container** — eine isolierte, sofort
lauffähige Instanz der Anwendung.

Der Vorteil für dich: Du musst **nichts** manuell installieren (kein Node.js,
kein n8n, keine Datenbank). Ein Befehl startet die komplette Challenge-Umgebung
— auf jedem Rechner gleich.

Diese Challenge besteht aus **drei Containern**, die zusammenarbeiten:

| Container | Was es macht | Port |
|-----------|--------------|------|
| `c2g-n8n` | n8n (Workflow-Automatisierung) + baramundi Connector | 5678 |
| `c2g-gateway` | MCP Gateway (13 KI-Server) | 3001 |
| `c2g-mock` | bConnect Mock (simulierte bMS-API) | 3433 |

**Docker Compose** ist das Werkzeug, das alle drei Container gemeinsam startet.
Die Datei `docker-compose.yml` beschreibt, welche Container laufen und wie sie
zusammenhängen.

---

## Kleines Glossar

| Begriff | Bedeutung |
|---------|-----------|
| **Image** | Bauplan/Vorlage einer Anwendung (schreibgeschützt) |
| **Container** | Eine laufende Instanz eines Images |
| **Volume** | Persistenter Speicher — überlebt einen Container-Neustart (hier: die n8n-Daten) |
| **Port-Mapping** | Verbindet einen Container-Port mit deinem Rechner (`5678:5678` = im Browser unter `localhost:5678` erreichbar) |
| **Compose** | Startet/stoppt mehrere Container gemeinsam per `docker-compose.yml` |

---

## Schritt 1 — Docker installieren

| Plattform | Was installieren |
|-----------|------------------|
| **Windows** | [Docker Desktop](https://www.docker.com/products/docker-desktop/) (enthält Compose) |
| **Mac** | [Docker Desktop](https://www.docker.com/products/docker-desktop/) (enthält Compose) |
| **Linux** | [Docker Engine](https://docs.docker.com/engine/install/) + Docker Compose Plugin |

Prüfe nach der Installation, ob alles bereit ist:

```bash
docker --version
docker compose version
```

Beide Befehle sollten eine Versionsnummer ausgeben. Unter Windows/Mac muss
**Docker Desktop laufen** (Wal-Symbol in der Taskleiste), bevor die Befehle
funktionieren.

> **Hinweis:** Ältere Linux-Systeme haben statt `docker compose` (mit Leerzeichen)
> nur das ältere `docker-compose` (mit Bindestrich). Ersetze dann in allen
> Befehlen `docker compose` durch `docker-compose`.

---

## Schritt 2 — Die wichtigsten Befehle

Alle Befehle führst du **im Projektverzeichnis** aus (dort, wo die
`docker-compose.yml` liegt).

**Umgebung starten** (`-d` = im Hintergrund):
```bash
docker compose up -d
```

**Status aller Container ansehen:**
```bash
docker compose ps
```

**Logs live mitlesen** (Abbruch mit `Strg+C`):
```bash
docker compose logs -f          # alle Container
docker compose logs -f n8n      # nur n8n
```

**Umgebung stoppen** (Container weg, Daten bleiben):
```bash
docker compose down
```

**Kompletter Reset** (Container **und** Daten/Volumes löschen — frischer Start):
```bash
docker compose down -v
docker compose up -d
```

> `down -v` ist dein Freund, wenn etwas klemmt: Es setzt n8n auf den
> Auslieferungszustand zurück und importiert die Beispiel-Workflows neu.

---

## Schritt 3 — Läuft alles?

Nach `docker compose up -d` dauert der erste Start ~1–2 Minuten (Images werden
geladen, n8n initialisiert sich). So prüfst du, ob alles bereit ist:

**1. Container-Status:**
```bash
docker compose ps
```
Alle drei Container sollten `Up` und `(healthy)` anzeigen. `starting` bedeutet
nur: bitte kurz warten.

**2. Im Browser öffnen:**
- n8n: <http://localhost:5678> — Login `demo@c2g.local` / `Baramundi2026`
- Gateway-Health: <http://localhost:3001/health> — sollte `OK` / Status 200 liefern
- Mock-Health: <http://localhost:3433/health> — sollte `OK` / Status 200 liefern

Wenn du die n8n-Oberfläche siehst und dich einloggen kannst, ist alles startklar.

---

## Fehlerbehebung

**„Cannot connect to the Docker daemon"**
→ Docker Desktop ist nicht gestartet. Starte es und warte, bis das Wal-Symbol
ruhig ist.

**„denied" / „unauthorized" beim Start**
→ Die Images liegen privat in der GitHub Container Registry. Du musst dich
einmalig anmelden — siehe
[An der GitHub Container Registry anmelden](../README.md#an-der-github-container-registry-anmelden-einmalig)
im README.

**„port is already allocated" / Port belegt**
→ Ein anderes Programm nutzt Port 3433, 3001 oder 5678. Beende es oder finde den
Verursacher:
```bash
# Linux / Mac
lsof -i :5678
# Windows (PowerShell)
netstat -ano | findstr :5678
```

**Container startet immer wieder neu / ist `unhealthy`**
→ Logs ansehen (`docker compose logs -f <name>`), dann einen sauberen Neustart
versuchen:
```bash
docker compose down -v && docker compose up -d
```

**n8n zeigt keine Workflows**
→ Die Beispiel-Workflows werden beim ersten Start automatisch importiert. Falls
nicht: `docker compose down -v && docker compose up -d` (setzt die Daten zurück).

**Alles ist langsam / bricht ab (Windows/Mac)**
→ Docker Desktop braucht genug RAM: **Settings → Resources → mind. 4 GB**.

Weitere challenge-spezifische Tipps findest du in
[challenge/TIPPS.md](../challenge/TIPPS.md).

---

## Und jetzt?

Zurück zum [Quick Start](../README.md#quick-start) und leg los. Wenn die drei
Container laufen, öffne n8n unter <http://localhost:5678> und schau dir die
Beispiel-Workflows an.
