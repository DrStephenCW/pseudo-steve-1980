#!/bin/sh
# Build the visual (WebAssembly) version into site/.
# Serve site/ as static files: nginx, or "go run . -http 127.0.0.1:8080 -site site".
set -e
cd "$(dirname "$0")"
GOOS=js GOARCH=wasm go build -ldflags=-s -o site/ps.wasm .
cp "$(go env GOROOT)/lib/wasm/wasm_exec.js" site/ 2>/dev/null || cp "$(go env GOROOT)/misc/wasm/wasm_exec.js" site/
ls -l site/
