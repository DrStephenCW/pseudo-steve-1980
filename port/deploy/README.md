# Hosting the web version

`ps -http 127.0.0.1:8080` serves a terminal-style page where each visitor
gets their own Pseudo-Steve. Sessions live in memory and are dropped after
30 idle minutes or when the visitor says "thank you". Nothing is logged or
stored. (The 1980 program logged every session to disk; this one does not.)

All URLs the page uses are relative, so it works at the root of a host or
behind nginx at a subpath such as `/pseudo-steve/`.

## Build

On the server (Go 1.21 or later):

    cd port
    go build -o ps .

Or cross-compile elsewhere for an ARM64 (Graviton) instance:

    cd port
    GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o ps-linux-arm64 .

The binary is self-contained: the tree, help text and page are embedded.

## Install

    sudo cp ps /usr/local/bin/pseudo-steve
    sudo cp deploy/pseudo-steve.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now pseudo-steve
    curl -s http://127.0.0.1:8080/healthz      # prints ok

Then add the `location` blocks from `deploy/nginx.conf` to your site and
run `sudo nginx -t && sudo systemctl reload nginx`.

## Options

    -http ADDR       listen address (use 127.0.0.1 so only nginx can reach it)
    -version jun|oct default version; visitors can switch on the page

## Endpoints

    GET  /           the page
    POST /start      {"version":"jun"}        -> {"id":..., "text":...}
    POST /say        {"id":..., "line":...}   -> {"text":..., "done":bool}
    GET  /healthz    ok
