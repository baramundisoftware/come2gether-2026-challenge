# baramundi come2gether 2026 Challenge

**Automatisiere eine wiederkehrende IT-Admin-Aufgabe mit n8n und/oder MCP mit der bConnect API.**

Dieses Repo liefert eine schluesselfertige Docker-Umgebung mit allem was du brauchst:

- **n8n** mit vorinstalliertem baramundi Connector (6 Nodes, 229 Operationen)
- **bConnect Mock** (simulierte bMS REST API mit realistischen Testdaten)
- **MCP Gateway** (13 KI-faehige MCP-Server fuer Claude und andere AI Agents)
- **3 Beispiel-Workflows** als Inspiration und Startpunkt

## Quick Start

```bash
git clone git@github.com:baramundisoftware/c2g-2026-challenge.git
cd c2g-2026-challenge
cp .env.example .env
docker compose up -d
```

Oeffne http://localhost:5678 — Login: `demo` / `baramundi`

> **Hinweis:** Falls dein System `docker-compose` (V1) nutzt, ersetze
> `docker compose` durch `docker-compose` in allen Befehlen.

## Architektur

```
┌─────────────────────────────────────────────────────────────┐
│  docker compose up                                          │
│                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────────┐  │
│  │ bconnect-mock│   │ mcp-gateway  │   │     n8n        │  │
│  │  :3433       │◄──│  :3001       │◄──│  :5678         │  │
│  │              │   │              │   │                │  │
│  │ bConnect API │   │ 13 MCP-      │   │ + Connector    │  │
│  │ (simuliert)  │   │ Server       │   │ + 3 Workflows  │  │
│  └──────────────┘   └──────────────┘   └────────────────┘  │
│                                                             │
│  Umschaltung Mock / Real: nur .env anpassen                 │
└─────────────────────────────────────────────────────────────┘
```

### Datenfluss

1. **n8n** fuehrt Workflows aus und nutzt den **baramundi Connector** oder **MCP Client Tools**
2. Der Connector spricht direkt mit der **bConnect REST API** (Mock oder Real)
3. Die MCP Client Tools sprechen mit dem **MCP Gateway**, der die Anfragen an bConnect weiterleitet
4. Der **bConnect Mock** simuliert eine vollstaendige baramundi Management Suite mit realistischen Daten

## Die 3 Beispiel-Workflows

### Workflow 1: Endpoint-Uebersicht (Einfach)

**Trigger:** Manuell | **Nodes:** 8

Holt alle Endpoints (Windows, Linux, Mac) ueber den baramundi Connector,
fuehrt sie zusammen und erzeugt eine HTML-Seite mit:
- Farbige Kacheln pro Endpoint-Typ (Zusammenfassung)
- Tabelle mit Hostname, Typ, OS, IP, Benutzer, letzter Kontakt
- baramundi Branding (Primaerblau #00a3e0, Dunkelblau #003c71)

**Lerneffekt:** n8n Grundlagen, Connector-Nutzung, Merge-Node, HTML-Templating

### Workflow 2: Software-Compliance (Mittel)

**Trigger:** Schedule (taeglich) + Manuell | **Nodes:** 11

Prueft installierte Software gegen konfigurierbare Regeln:
- **Allowlist:** Erlaubte Standard-Software (Office, Chrome, Teams, ...)
- **Blocklist:** Verbotene Software (Torrent, Spiele, Remote-Tools)
- **Pflicht-Software:** Muss installiert sein (Office, Chrome)
- **Versionscheck:** Veraltete Versionen erkennen (Java, Acrobat)

Erzeugt einen HTML-Report mit Ampel-System (Konform / Warnung / Kritisch)
oder eine kurze "Alles OK" Meldung.

**Lerneffekt:** Scheduled Workflows, Daten-Enrichment (Endpoints + Software),
bedingte Logik (IF-Node), praxisnahe IT-Compliance

### Workflow 3: KI-Infrastruktur-Berater (Fortgeschritten)

**Trigger:** Manuell | **Nodes:** 8 | **Braucht:** Anthropic API Key

Claude AI Agent mit drei MCP-Server-Anbindungen:
- **MCP: Endpoints** — 47 Tools fuer Endpoint-Verwaltung
- **MCP: Jobs** — 24 Tools fuer Job-Management
- **MCP: Compliance** — 8 Tools fuer Compliance und Schwachstellen

Der Agent entscheidet autonom, welche Tools er aufruft, und erzeugt
einen strukturierten Infrastruktur-Gesundheitsbericht.

**Lerneffekt:** KI-Agenten, MCP-Protokoll, Tool-Use, autonome Entscheidungsfindung

## Mock oder echtes bConnect?

Die `.env`-Datei steuert das Ziel. Default ist der Mock — kein echtes bMS noetig.

```env
# Mock (Default)
BCONNECT_BASE_URL=http://bconnect-mock:3433/bconnect

# Echtes bMS (anpassen):
# BCONNECT_BASE_URL=https://bms.example.com:444/bconnect
# BCONNECT_API_KEY=dein-api-key
```

Nach Aenderung: `docker compose down -v && docker compose up -d`

### Mock-Daten

Der bConnect Mock liefert realistische Testdaten:

| Datentyp | Anzahl | Details |
|----------|--------|---------|
| Windows Endpoints | 10 | NYC, London, Berlin, Singapore, ... |
| Linux Endpoints | 3 | verschiedene Distributionen |
| Mac Endpoints | 2 | macOS |
| Software-Titel | 10 | Office, Chrome, Teams, 7-Zip, ... |
| Job-Definitionen | 5 | verschiedene Job-Typen |
| Compliance Rules | mehrere | 26R1-spezifisch |
| Vulnerabilities | mehrere | CVSS-Scores, CVE-IDs |

## KI-Workflow (Workflow 3)

Fuer den KI-Workflow brauchst du einen Anthropic API Key:

1. Key erstellen: https://console.anthropic.com/
2. In `.env` eintragen: `ANTHROPIC_API_KEY=dein-key-hier`
3. Container neu starten: `docker compose down -v && docker compose up -d`
4. In n8n: Credential "Anthropic API" mit dem Key konfigurieren

Workflows 1 und 2 funktionieren auch ohne API Key.

## Deine Challenge

| Dokument | Inhalt |
|----------|--------|
| [challenge/AUFGABE.md](challenge/AUFGABE.md) | Aufgabenstellung und Regeln |
| [challenge/BEWERTUNG.md](challenge/BEWERTUNG.md) | Bewertungskriterien (100 Punkte) |
| [challenge/TIPPS.md](challenge/TIPPS.md) | Hilfreiche Tipps, Node-Referenz, Fehlerbehebung |

## Projektstruktur

```
c2g-2026-challenge/
├── README.md                          # Diese Datei
├── docker-compose.yml                 # 3 Services: Mock + Gateway + n8n
├── .env.example                       # Konfigurations-Vorlage
├── Makefile                           # build, test, clean
│
├── workflows/
│   ├── 01-endpoint-overview.json      # Einfach: Endpoint-HTML-Uebersicht
│   ├── 02-software-compliance.json    # Mittel: Compliance mit Ampel-Report
│   └── 03-ai-infra-advisor.json       # KI: Claude + 3 MCP Server
│
├── challenge/
│   ├── AUFGABE.md                     # Aufgabenstellung
│   ├── BEWERTUNG.md                   # Bewertungskriterien
│   └── TIPPS.md                       # Hilfreiche Links und Tipps
│
├── branding/
│   ├── baramundi-logo.svg             # Logo fuer HTML-Reports
│   └── styles.css                     # baramundi CSS-Farbschema
│
└── tests/                             # BATS-Testsuite (45 Tests)
    ├── lint.sh                        # Statische Analyse + Security
    ├── smoke.bats                     # Container-Startup (11 Tests)
    ├── workflow-01.bats               # Workflow 1 Struktur (8 Tests)
    ├── workflow-02.bats               # Workflow 2 Struktur (9 Tests)
    ├── workflow-03.bats               # Workflow 3 Struktur (9 Tests)
    ├── mcp-gateway.bats               # MCP Gateway (3 Tests)
    ├── switch-target.bats             # Mock/Real Umschaltung (5 Tests)
    └── helpers/
        └── setup.bash                 # BATS-Hilfsfunktionen
```

## Fehlerbehebung

**Container starten nicht?**
```bash
docker compose logs -f        # Logs pruefen
docker compose down -v         # Neustart mit frischen Volumes
docker compose up -d
```

**n8n zeigt keine Workflows?**
- Die Workflows werden beim ersten Start automatisch importiert (Seed-Mechanismus)
- Bei Problemen: `docker compose down -v && docker compose up -d` (Volumes zuruecksetzen)

**MCP-Tools nicht verfuegbar?**
- Gateway-Health pruefen: `curl http://localhost:3001/health`
- MCP-URLs in n8n muessen `http://mcp-gateway:3001/...` sein (Docker-Netzwerk)

## Lizenz

MIT
