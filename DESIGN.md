# DESIGN.md — mcp-probe

## Overview

**mcp-probe** è un wrapper CLI agnostico scritto in Bash progettato per **testare server MCP (Model Context Protocol)** tramite diversi client LLM e tool agentici.

Lo strumento nasce per risolvere un problema pratico:

> Quando sviluppi un server MCP vuoi verificare che **diversi agenti o chat client siano in grado di usare correttamente i tool esposti**.

Molti client supportano MCP ma:

* hanno CLI diverse
* cambiano flag e formati
* spesso sono pensati per uso interattivo

**mcp-probe unifica queste interfacce in un unico comando stabile**, ideale per:

* integration testing
* CI pipelines
* smoke testing
* debugging di server MCP
* test multi-provider

---

# Goals

mcp-probe ha i seguenti obiettivi principali:

### 1. CLI unificata

Permettere una singola sintassi:

```
mcp-probe \
  --prompt "che ore sono in cina" \
  --server localhost:9090
```

indipendentemente dal client utilizzato.

---

### 2. Test agentico reale

Non si limita a chiamare direttamente i tool MCP.

L'obiettivo è verificare che:

* l'LLM **scopra i tool**
* l'LLM **decida di usarli**
* il tool venga **invocato correttamente**

Questo permette di validare l'intero flusso:

```
LLM
  ↓
tool selection
  ↓
MCP client
  ↓
MCP server
```

---

### 3. Compatibilità multi-client

mcp-probe supporta diversi client tramite wrapper:

| Client     | Modalità  |
| ---------- | --------- |
| claude     | CLI agent |
| gemini     | CLI agent |
| openai     | API       |
| ollama     | locale    |
| codex-like | CLI       |

Ogni client è implementato come **plugin wrapper**.

---

### 4. Automazione CI

mcp-probe è pensato per essere usato in:

* GitHub Actions
* GitLab CI
* Jenkins
* script bash locali

Esempio:

```
mcp-probe \
  --client ollama \
  --server localhost:9090 \
  --prompt "che ore sono in cina"
```

Exit code:

```
0 = successo
1 = errore
2 = tool non utilizzato
```

---

# CLI Design

Sintassi principale:

```
mcp-probe [options]
```

## Flags

### Prompt

```
--prompt TEXT
```

Prompt da inviare all'agente.

---

### MCP server

```
--server URL
```

Endpoint del server MCP.

Esempio:

```
--server localhost:9090
--server http://localhost:9090
```

---

### Client

```
--client NAME
```

Client da utilizzare.

Esempi:

```
--client ollama
--client claude
--client gemini
--client openai
```

---

### Non interactive

```
--no-interactive
```

Forza esecuzione batch.

---

### Expect tool

Permette di verificare che un tool venga utilizzato.

```
--expect-tool TOOL_NAME
```

Se il tool non viene chiamato:

```
exit 2
```

---

### Verbose

```
--verbose
```

Stampa debug:

* tool list
* reasoning
* request MCP

---

# Architettura

mcp-probe segue una struttura modulare.

```
mcp-probe
 ├── mcp-probe (main bash script)
 ├── clients/
 │   ├── ollama.sh
 │   ├── claude.sh
 │   ├── gemini.sh
 │   ├── openai.sh
 │
 ├── transports/
 │   ├── local.sh
 │   ├── http.sh
 │
 └── utils/
     ├── logging.sh
     └── parsing.sh
```

---

# Client Wrappers

Ogni client è implementato come wrapper bash.

Interfaccia standard:

```
run_client PROMPT MCP_SERVER
```

Esempio:

```
run_client() {
  local prompt="$1"
  local server="$2"
}
```

---

## Ollama wrapper

Esegue un modello locale.

Esempio:

```
ollama run llama3 \
  "Use MCP tools from $SERVER. $PROMPT"
```

---

## Claude wrapper

Usa la CLI Claude.

```
claude \
  --print \
  --mcp-server "$SERVER" \
  "$PROMPT"
```

---

## Gemini wrapper

```
gemini chat \
  --prompt "$PROMPT" \
  --tools mcp="$SERVER"
```

---

## OpenAI wrapper

Utilizza curl verso API OpenAI.

```
curl https://api.openai.com/v1/responses
```

con tool MCP configurati.

---

# Remote Testing

mcp-probe può testare server MCP pubblici tramite tunnel.

Supporto per:

* ngrok
* cloudflare tunnel
* ssh reverse tunnel

---

## ngrok wrapper

Esempio:

```
ngrok http 9090
```

Restituisce:

```
https://abc123.ngrok.io
```

mcp-probe può usarlo automaticamente:

```
mcp-probe \
  --ngrok 9090 \
  --client openai
```

Workflow:

```
local MCP server
        ↓
ngrok tunnel
        ↓
public URL
        ↓
remote LLM
```

---

# Remote LLM Testing

mcp-probe consente test con LLM remoti.

Esempio:

```
mcp-probe \
  --client openai \
  --server https://abc.ngrok.io \
  --prompt "che ore sono in cina"
```

Questo permette di verificare:

* compatibilità tool schema
* accessibilità server
* latenza
* comportamento agentico

---

# Exit Codes

| Code | Significato                  |
| ---- | ---------------------------- |
| 0    | successo                     |
| 1    | errore esecuzione            |
| 2    | tool non utilizzato          |
| 3    | server MCP non raggiungibile |

---

# Esempi

### Test locale

```
mcp-probe \
  --client ollama \
  --server localhost:9090 \
  --prompt "che ore sono in cina"
```

---

### Test CI

```
mcp-probe \
  --client ollama \
  --server localhost:9090 \
  --prompt "dimmi l'ora in cina usando i tool"
```

---

### Test tool specifico

```
mcp-probe \
  --expect-tool get_time \
  --prompt "che ore sono in cina"
```

---

### Test remoto

```
mcp-probe \
  --client openai \
  --server https://abc.ngrok.io \
  --prompt "che ore sono in cina"
```

---

# Filosofia del progetto

mcp-probe segue alcuni principi:

### Unix philosophy

* semplice
* scriptabile
* composabile

---

### Bash-first

Il tool è scritto in bash per:

* portabilità
* integrazione CI
* facilità di hacking

---

### LLM agnostic

Non è legato a un singolo provider.

---

### MCP-first

L'obiettivo principale è:

> rendere **facile testare server MCP**.

---

# Possibili Estensioni Future

### Test suite MCP

```
mcp-probe test suite.yaml
```

---

### Parallel probing

Test con più client in parallelo.

```
mcp-probe \
  --clients ollama,claude,openai
```

---

### Benchmark

Misurare:

* tempo risposta
* successo tool
* latenza

---

### Recording

Salvare transcript dei test:

```
tests/logs/
```

---

# Conclusione

mcp-probe è un **probe universale per server MCP**.

Permette di verificare rapidamente:

* che i tool siano accessibili
* che gli agenti li usino
* che i server funzionino con client diversi

È pensato come **strumento leggero ma potente** per lo sviluppo di ecosistemi MCP.
