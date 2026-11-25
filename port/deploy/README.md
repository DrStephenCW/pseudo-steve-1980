# Hosting Pseudo-Steve

There are two web versions. Pick one or run both.

## Visual version (WebAssembly)

`site/` is a static page that runs the program in the browser and shows its
working: the words it used, the path through the knowledge tree, the
two-search memory, and which inference rule chose the reply. It needs no
server process.

    cd port
    ./build-site.sh                       # writes site/ps.wasm and site/wasm_exec.js
    sudo mkdir -p /var/www/pseudo-steve
    sudo cp site/index.html site/ps.wasm site/wasm_exec.js /var/www/pseudo-steve/

Then add the first `location` blocks from `deploy/nginx.conf` and run
`sudo nginx -t && sudo systemctl reload nginx`. ps.wasm is about 3 MB
(under 1 MB gzipped), so keep the gzip line.

To try it locally (Windows or Linux): `go run . -http 127.0.0.1:8080 -site site`,
then open http://127.0.0.1:8080/. Opening index.html straight from disk
does not work, because browsers will not load .wasm from file://.

## Plain terminal version (Go server)

`ps -http 127.0.0.1:8080` serves a terminal-style page where each visitor
gets their own Pseudo-Steve. Sessions live in memory and are dropped after
30 idle minutes or when the visitor says "thank you". Nothing is logged.

    cd port
    go build -o ps .
    sudo cp ps /usr/local/bin/pseudo-steve
    sudo cp deploy/pseudo-steve.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now pseudo-steve
    curl -s http://127.0.0.1:8080/healthz      # prints ok

Use the commented `location` block in `deploy/nginx.conf`.

Endpoints: `GET /` page, `POST /start {"version":"jun"}`,
`POST /say {"id":...,"line":...}`, `GET /healthz`.
