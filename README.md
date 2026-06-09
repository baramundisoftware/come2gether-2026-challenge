# baramundi come2gether 2026 Challenge

**Automatisiere eine wiederkehrende IT-Admin-Aufgabe mit n8n und/oder MCP mit der bConnect API.**

Dieses Repo liefert eine schluesselfertige Docker-Umgebung mit allem was du brauchst:

- **n8n** mit vorinstalliertem baramundi Connector (6 Nodes, 229 Operationen)
- **bConnect Mock** (simulierte bMS REST API mit realistischen Testdaten)
- **MCP Gateway** (13 KI-faehige MCP-Server fuer Claude und andere Agenten)
- **3 Beispiel-Workflows** als Inspiration und Startpunkt

## Quick Start

```bash
git clone git@github.com:baramundisoftware/c2g-2026-challenge.git
cd c2g-2026-challenge
cp .env.example .env
docker compose up -d
```

Oeffne http://localhost:5678 — Login: `demo` / `baramundi`

## Architektur

```
docker compose up
     |
     v
+----------------+   +----------------+   +----------------+
| bconnect-mock  |<--| mcp-gateway    |<--| n8n            |
| :3433          |   | :3001          |   | :5678          |
| bConnect API   |   | 13 MCP-Server  |   | + Connector    |
| (simuliert)    |   | (212 Tools)    |   | + 3 Workflows  |
+----------------+   +----------------+   +----------------+
```

## Die 3 Beispiel-Workflows

| # | Schwierigkeit | Workflow | Beschreibung |
|---|--------------|----------|--------------|
| 1 | Einfach | Endpoint-Uebersicht | Alle Endpoints abrufen, als HTML mit baramundi Branding darstellen |
| 2 | Mittel | Software-Compliance | Installierte Software gegen Allowlist pruefen, Ampel-Report |
| 3 | KI | Infrastruktur-Berater | Claude AI Agent + 3 MCP-Server fuer natuerlichsprachliche Analyse |

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

## KI-Workflow (Workflow 3)

Fuer den KI-Workflow brauchst du einen Anthropic API Key.
Erstelle einen unter https://console.anthropic.com/ und trage ihn in `.env` ein:

```env
ANTHROPIC_API_KEY=dein-key-hier
```

Workflows 1 und 2 funktionieren auch ohne API Key.

## Deine Challenge

Siehe [challenge/AUFGABE.md](challenge/AUFGABE.md) fuer die vollstaendige Aufgabenbeschreibung.

## Lizenz

MIT
