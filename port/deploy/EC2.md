# Deploy Pseudo-Steve (visual WebAssembly version) on the EC2 instance

Target: Amazon Linux 2023, ARM64 (Graviton), nginx already running.
Result: https://<your-host>/pseudo-steve/  (static files only, no server process)

## 1. One-time setup
    sudo dnf install -y git golang          # Go 1.21 or newer is needed
    go version
    sudo mkdir -p /opt/src /var/www/pseudo-steve
    sudo chown "$USER" /opt/src
    git clone https://github.com/DrStephenCW/pseudo-steve-1980 /opt/src/pseudo-steve-1980

## 2. Build and install (repeat this to update)
    cd /opt/src/pseudo-steve-1980
    git fetch origin && git reset --hard origin/main   # safe even if history was rewritten
    cd port
    go test ./...                 # replays the 1980 paper's run; must print ok
    ./build-site.sh               # writes site/ps.wasm and site/wasm_exec.js
    sudo cp site/index.html site/ps.wasm site/wasm_exec.js /var/www/pseudo-steve/

## 3. nginx (inside the server { } block for the site, then reload)
    location = /pseudo-steve { return 301 /pseudo-steve/; }
    location /pseudo-steve/ {
        alias /var/www/pseudo-steve/;
        types { application/wasm wasm; text/html html; application/javascript js; }
        gzip on;
        gzip_types application/wasm application/javascript;
    }

    sudo nginx -t && sudo systemctl reload nginx

## 4. Check
    curl -sI https://<your-host>/pseudo-steve/ps.wasm | grep -i content-type   # application/wasm
    curl -s  https://<your-host>/pseudo-steve/ | grep -o '<title>.*</title>'    # <title>Pseudo-Steve</title>
Then open the page: the terminal should show "The compiler is due June 5..."
and the panels should be filled in.

Notes
- The page loads Google Fonts; nothing else external. No cookies, no logging.
- If SELinux blocks nginx from /var/www/pseudo-steve: sudo restorecon -R /var/www/pseudo-steve
- The optional plain terminal server (ps -http) is described in port/deploy/README.md; it is not needed for this.
