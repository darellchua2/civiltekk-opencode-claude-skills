# docling-mcp-server defaults to streamable-http, not stdio

**Type:** solution
**Confidence:** 0.95 (verified: bare spawn ignores MCP initialize on stdin; `--transport stdio` answers)
**Scope:** any `mcp.servers.docling` (or docling-mcp-backed) local server config

## Problem

`docling-mcp-server` (PyPI `docling-mcp[local]`) defaults to `--transport streamable-http` — it starts a uvicorn HTTP app and never speaks stdio. OpenCode (`type: "local"`, stdio) gets silence and reports `MCP error -32000: Connection closed`, even though the binary spawns cleanly. Fix: `command: ["docling-mcp-server", "--transport", "stdio"]`. Also: its pip install needs `--break-system-packages` on PEP 668 Ubuntu (install_docling retry added), and first convert downloads ~hundreds of MB of HF models.

## Diagnosis trick

Feed a real JSON-RPC `initialize` over stdin with the pipe held open — a stdio server must answer on stdout. Silence with clean stderr logs = wrong transport, not a crash.
