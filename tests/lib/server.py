#!/usr/bin/env python3
"""
Minimal MCP HTTP server for integration testing.
Implements two tools:
  - get_world_time(timezone)  → current time in that timezone
  - get_holidays(country, year) → list of public holidays
"""
import json
import sys
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

try:
    import zoneinfo
except ImportError:
    import backports.zoneinfo as zoneinfo  # Python < 3.9 fallback

HOLIDAYS = {
    "IT": [
        {"date": "YEAR-01-01", "name": "Capodanno"},
        {"date": "YEAR-01-06", "name": "Epifania"},
        {"date": "YEAR-04-25", "name": "Festa della Liberazione"},
        {"date": "YEAR-05-01", "name": "Festa dei Lavoratori"},
        {"date": "YEAR-06-02", "name": "Festa della Repubblica"},
        {"date": "YEAR-08-15", "name": "Ferragosto"},
        {"date": "YEAR-11-01", "name": "Ognissanti"},
        {"date": "YEAR-12-08", "name": "Immacolata Concezione"},
        {"date": "YEAR-12-25", "name": "Natale"},
        {"date": "YEAR-12-26", "name": "Santo Stefano"},
    ],
    "US": [
        {"date": "YEAR-01-01", "name": "New Year's Day"},
        {"date": "YEAR-07-04", "name": "Independence Day"},
        {"date": "YEAR-11-11", "name": "Veterans Day"},
        {"date": "YEAR-12-25", "name": "Christmas Day"},
    ],
    "FR": [
        {"date": "YEAR-01-01", "name": "Jour de l'An"},
        {"date": "YEAR-05-01", "name": "Fête du Travail"},
        {"date": "YEAR-07-14", "name": "Fête Nationale"},
        {"date": "YEAR-12-25", "name": "Noël"},
    ],
}


class MCPHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass  # suppress default access log

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)

        try:
            request = json.loads(body)
        except json.JSONDecodeError:
            self._respond_error(-32700, "Parse error", None)
            return

        method = request.get("method", "")
        req_id = request.get("id")
        params = request.get("params", {})

        if method == "initialize":
            result = {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "mcp-probe-test-server", "version": "1.0.0"},
            }
        elif method == "notifications/initialized":
            self.send_response(204)
            self.end_headers()
            return
        elif method == "tools/list":
            result = {
                "tools": [
                    {
                        "name": "get_world_time",
                        "description": "Get the current date and time in a given IANA timezone",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "timezone": {
                                    "type": "string",
                                    "description": "IANA timezone name (e.g. Asia/Shanghai, Europe/Rome)",
                                }
                            },
                            "required": ["timezone"],
                        },
                    },
                    {
                        "name": "get_holidays",
                        "description": "Get public holidays for a country in a given year",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "country": {
                                    "type": "string",
                                    "description": "ISO 3166-1 alpha-2 country code (IT, US, FR)",
                                },
                                "year": {
                                    "type": "integer",
                                    "description": "Year (e.g. 2026)",
                                },
                            },
                            "required": ["country", "year"],
                        },
                    },
                ]
            }
        elif method == "tools/call":
            name = params.get("name", "")
            args = params.get("arguments", {})

            if name == "get_world_time":
                tz_name = args.get("timezone", "UTC")
                try:
                    tz = zoneinfo.ZoneInfo(tz_name)
                    now = datetime.now(tz)
                    text = "Current time in {}: {}".format(
                        tz_name, now.strftime("%Y-%m-%d %H:%M:%S %Z")
                    )
                except Exception:
                    text = "Unknown timezone: {}".format(tz_name)
                result = {"content": [{"type": "text", "text": text}]}

            elif name == "get_holidays":
                country = args.get("country", "IT").upper()
                year = int(args.get("year", datetime.now().year))
                entries = HOLIDAYS.get(country)
                if not entries:
                    text = "No holiday data available for country: {}".format(country)
                else:
                    lines = ["Public holidays in {} ({}):".format(country, year)]
                    for h in entries:
                        date = h["date"].replace("YEAR", str(year))
                        lines.append("  {}: {}".format(date, h["name"]))
                    text = "\n".join(lines)
                result = {"content": [{"type": "text", "text": text}]}

            else:
                self._respond_error(-32601, "Unknown tool: {}".format(name), req_id)
                return
        else:
            self._respond_error(-32601, "Method not found: {}".format(method), req_id)
            return

        self._respond({"jsonrpc": "2.0", "id": req_id, "result": result})

    def _respond(self, data):
        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _respond_error(self, code, message, req_id):
        self._respond({
            "jsonrpc": "2.0",
            "id": req_id,
            "error": {"code": code, "message": message},
        })


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 9090
    httpd = HTTPServer(("localhost", port), MCPHandler)
    print("MCP test server listening on port {}".format(port), flush=True)
    httpd.serve_forever()
