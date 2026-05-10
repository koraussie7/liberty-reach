import http.server, urllib.request, json, os, mimetypes

LOCALAI = "http://localhost:8081"
PORT = 80

class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/v1/") or self.path == "/healthz":
            self.proxy("GET")
        else:
            super().do_GET()

    def do_POST(self):
        if self.path.startswith("/v1/"):
            self.proxy("POST")
        else:
            self.send_error(405)

    def do_OPTIONS(self):
        self.send_cors()
        self.send_response(200)
        self.end_headers()

    def send_cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def proxy(self, method):
        url = LOCALAI + self.path
        body = None
        if method == "POST":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)

        req = urllib.request.Request(url, data=body, method=method)
        req.add_header("Content-Type", "application/json")
        for h in ["Accept"]:
            if h in self.headers:
                req.add_header(h, self.headers[h])

        try:
            with urllib.request.urlopen(req, timeout=120) as res:
                data = res.read()
                self.send_response(res.status)
                self.send_cors()
                self.send_header("Content-Type", res.headers.get("Content-Type", "application/json"))
                self.send_header("Content-Length", len(data))
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            data = e.read()
            self.send_response(e.code)
            self.send_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self.send_response(502)
            self.send_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())

    def log_message(self, fmt, *a):
        pass

if __name__ == "__main__":
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else PORT
    server = http.server.HTTPServer(("0.0.0.0", port), ProxyHandler)
    print(f"Serving at http://0.0.0.0:{port}  (proxying /v1/* -> {LOCALAI})")
    server.serve_forever()
