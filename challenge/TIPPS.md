# Tipps und Ressourcen

## Schnellstart

Siehe Quick Start im README für die plattformspezifischen Befehle.

Öffne http://localhost:5678 — Login: `demo` / `baramundi`

## Die 3 Beispiel-Workflows

Starte mit den vorinstallierten Workflows als Inspiration:

1. **Endpoint-Übersicht** (Einfach) — Alle Endpoints abrufen und als HTML darstellen
2. **Software-Compliance** (Mittel) — Software gegen Allowlist prüfen mit Ampel-Report
3. **KI-Infrastruktur-Berater** (KI) — Claude AI Agent analysiert die Infrastruktur

## baramundi Connector Nodes

Der Connector bietet 6 Nodes mit insgesamt 229 Operationen:

| Node | Beispiel-Operationen |
|------|---------------------|
| **Endpoint** | getMany, get, search, create, update, delete |
| **Software** | getInstalledWindowsSoftware, getBundles, getVariables |
| **Job** | getMany, execute, getInstances, abort |
| **Asset** | getMany, create, update, getAssetTypes |
| **Admin** | getADUsers, getADGroups, getMicroservices |
| **Security** | getComplianceRules, getVulnerabilities, getDefenseControl |

**Tipp:** Setze `bmsVersion` auf `26R1` für alle Features.

## MCP-Server (für KI-Workflows)

Der MCP Gateway stellt 13 Domänen bereit. Die wichtigsten:

| Pfad | Tools | Beschreibung |
|------|-------|-------------|
| `/endpoints/mcp` | 47 | Endpoint-Verwaltung |
| `/jobs/mcp` | 24 | Job-Verwaltung |
| `/compliance/mcp` | 8 | Compliance und Schwachstellen |
| `/software/mcp` | 15 | Software-Inventar |
| `/assets/mcp` | 22 | Asset-Verwaltung |
| `/admin/mcp` | 33 | AD, Server, Microservices |
| `/security/mcp` | 12 | Defense Control, BitLocker |

**Nutzung in n8n:** Füge einen "MCP Client Tool" Node hinzu und verbinde ihn mit
einem "AI Agent" Node. Die URL ist `http://mcp-gateway:3001/<domain>/mcp`.

## Mock-Daten

Der bConnect Mock liefert realistische Testdaten:

- 10 Windows-Endpoints (NYC, London, Berlin, Singapore, ...)
- 3 Linux-Endpoints
- 2 Mac-Endpoints
- 10 Software-Titel (Office, Chrome, Teams, 7-Zip, ...)
- 5 Job-Definitionen
- Compliance-Rules und Vulnerabilities (26R1)

## Hilfreiche n8n-Nodes

| Node | Wofür |
|------|-------|
| **Code** | JavaScript/Python für Datenverarbeitung |
| **IF** | Bedingte Verzweigung |
| **Merge** | Daten zusammenführen |
| **HTML** | HTML-Ausgabe anzeigen |
| **Schedule Trigger** | Zeitgesteuerte Ausführung |
| **Webhook** | HTTP-Endpunkt erstellen |
| **AI Agent** | KI-Agent mit Tool-Zugriff |
| **MCP Client Tool** | MCP-Server anbinden |

## KI-Workflow einrichten (Workflow 3)

1. Anthropic API Key erstellen: https://console.anthropic.com/
2. In `.env` eintragen: `ANTHROPIC_API_KEY=dein-key`
3. Container neu starten: `docker compose down -v && docker compose up -d`
4. In n8n: Credential "Anthropic API" mit dem Key konfigurieren

## Fehlerbehebung

**Container starten nicht?**
```bash
docker compose down -v
docker compose up -d
docker compose logs -f
```

**Endpoints leer?**
- Prüfe ob der Mock läuft: http://localhost:3433/health im Browser öffnen
- Credential in n8n prüfen (Settings > Credentials)

**MCP-Tools nicht verfügbar?**
- Gateway-Health prüfen: http://localhost:3001/health im Browser öffnen
- MCP-URL muss `http://mcp-gateway:3001/...` sein (Docker-internes Netzwerk)

**Windows: Docker-Probleme?**
- Docker Desktop muss laufen
- Mindestens 4 GB RAM in Docker Desktop zuweisen (Settings → Resources)
- Falls Ports blockiert: Windows Firewall / VPN prüfen

## Links

- [n8n Dokumentation](https://docs.n8n.io/)
- [n8n Node Reference](https://docs.n8n.io/integrations/builtin/core-nodes/)
- [MCP Protokoll](https://modelcontextprotocol.io/)
- [Anthropic API](https://docs.anthropic.com/)
