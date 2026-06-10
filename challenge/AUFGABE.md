# come2gether 2026 Challenge

## Deine Aufgabe

**Automatisiere eine wiederkehrende IT-Admin-Aufgabe mit n8n und/oder MCP mit der bConnect API.**

Erstelle einen n8n-Workflow, der ein reales Problem aus dem IT-Alltag loest.
Nutze dazu die baramundi bConnect API (ueber den vorinstallierten Connector oder die MCP-Server).

## Was du bekommst

Diese Docker-Umgebung liefert dir alles, was du brauchst:

- **n8n** mit vorinstalliertem baramundi Connector (6 Nodes, 229 Operationen)
- **bConnect Mock** — eine simulierte bMS REST API mit realistischen Testdaten
- **MCP Gateway** — 13 KI-faehige MCP-Server fuer Claude und andere AI Agents
- **3 Beispiel-Workflows** als Inspiration

Du brauchst kein echtes baramundi Management Suite. Der Mock liefert realistische
Daten fuer Endpoints, Software, Jobs, Compliance, Assets und mehr.

## Regeln

1. **Ein Workflow** pro Teilnehmer/Team
2. Der Workflow muss die **bConnect API** nutzen (Connector-Nodes oder MCP)
3. Der Workflow muss ein **praxisrelevantes IT-Admin-Problem** loesen
4. **Dokumentation:** Kurzes README mit Beschreibung, was der Workflow tut und warum
5. Bonus: KI-Einsatz (Claude via MCP) wird extra bewertet

## Abgabe

Exportiere deinen Workflow als JSON aus n8n:
1. Workflow oeffnen
2. Menu (drei Punkte) > "Download"
3. Die `.json`-Datei zusammen mit einem kurzen README einreichen

## Ideen fuer Workflows

Hier ein paar Anregungen — du kannst aber auch etwas voellig Eigenes bauen:

- **Patch-Status-Dashboard:** Zeige den Windows-Update-Status aller Endpoints
- **Stale-Endpoint-Alarm:** Finde Endpoints, die seit X Tagen offline sind
- **Job-Failure-Alert:** Benachrichtige bei fehlgeschlagenen Jobs per Slack/E-Mail
- **Asset-Inventur:** Erstelle einen Bericht aller verwalteten Assets
- **Security-Audit:** Pruefe Compliance-Rules und Vulnerabilities
- **Onboarding-Workflow:** Automatisiere die Einrichtung neuer Endpoints
- **KI-Chat-Bot:** Natuerlichsprachliche Abfragen der Infrastruktur per Claude + MCP
- **Lizenz-Uebersicht:** Zaehle Software-Installationen fuer Lizenz-Management

## Zeitrahmen

Du hast waehrend des come2gether Events Zeit, deinen Workflow zu bauen.
Die Beispiel-Workflows helfen dir beim Einstieg — schau sie dir an und
experimentiere frei.

Viel Erfolg und Spass!
