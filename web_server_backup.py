import http.server
import urllib.request
import json
import os

PORT = 9090
LOCAL_AI = "http://localhost:8081"
DIR = os.path.dirname(os.path.abspath(__file__))

class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path.startswith("/v1/"):
            content_len = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_len)
            target = LOCAL_AI + self.path
            try:
                req = urllib.request.Request(target, data=body, headers={"Content-Type": "application/json"}, method="POST")
                resp = urllib.request.urlopen(req, timeout=120)
                self.send_response(resp.status)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(resp.read())
            except urllib.error.HTTPError as e:
                self.send_response(e.code)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(e.read())
            except Exception as e:
                self.send_response(502)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(str(e).encode())
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not found")

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        if self.path == "/healthz":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(b"ok")
        elif self.path.startswith("/v1/"):
            target = LOCAL_AI + self.path
            try:
                req = urllib.request.Request(target)
                resp = urllib.request.urlopen(req, timeout=30)
                self.send_response(resp.status)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(resp.read())
            except urllib.error.HTTPError as e:
                self.send_response(e.code)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(e.read())
        else:
            path = self.translate_path(self.path)
            if os.path.isfile(path):
                self.send_response(200)
                ctype = self.guess_type(path)
                self.send_header("Content-Type", ctype)
                self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
                self.send_header("Pragma", "no-cache")
                self.send_header("Expires", "0")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                with open(path, "rb") as f:
                    self.wfile.write(f.read())
            else:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b"Not found")

if __name__ == "__main__":
    os.chdir(DIR)
    server = http.server.HTTPServer(("0.0.0.0", PORT), ProxyHandler)
    print(f"Web server on :{PORT}, proxying /v1/* -> {LOCAL_AI}")
    server.serve_forever()
