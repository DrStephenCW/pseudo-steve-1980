//go:build !js

package main

// Web mode: ps -http 127.0.0.1:8080
//
// Each browser gets its own Pseudo-Steve, kept in memory and dropped after
// 30 idle minutes. Every URL the page uses is relative, so it works the
// same at / or behind a proxy at a subpath such as /pseudo-steve/.

import (
	"bufio"
	"bytes"
	"crypto/rand"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"log"
	"mime"
	"net/http"
	"sync"
	"time"
)

//go:embed web/index.html
var indexHTML []byte

const (
	maxSessions = 2000
	idleTimeout = 30 * time.Minute
	maxLine     = 500
)

type session struct {
	ps   *PS
	buf  *bytes.Buffer
	last time.Time
}

type server struct {
	tree    map[Atom]List
	version string
	mu      sync.Mutex
	s       map[string]*session
}

func newID() string {
	b := make([]byte, 16)
	rand.Read(b)
	return hex.EncodeToString(b)
}

// output returns what the session printed since the last call.
func (se *session) output() string {
	se.ps.out.Flush()
	t := se.buf.String()
	se.buf.Reset()
	return t
}

func (sv *server) reap() {
	for range time.Tick(time.Minute) {
		sv.mu.Lock()
		for id, se := range sv.s {
			if time.Since(se.last) > idleTimeout {
				delete(sv.s, id)
			}
		}
		sv.mu.Unlock()
	}
}

type reply struct {
	ID   string `json:"id,omitempty"`
	Text string `json:"text"`
	Done bool   `json:"done"`
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	json.NewEncoder(w).Encode(v)
}

func (sv *server) start(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "POST only", http.StatusMethodNotAllowed)
		return
	}
	var req struct {
		Version string `json:"version"`
	}
	json.NewDecoder(http.MaxBytesReader(w, r.Body, 1024)).Decode(&req)
	v := sv.version
	if req.Version == "jun" || req.Version == "oct" {
		v = req.Version
	}
	buf := &bytes.Buffer{}
	se := &session{buf: buf, last: time.Now(),
		ps: &PS{tree: sv.tree, version: v, out: bufio.NewWriter(buf), tidy: true}}
	se.ps.Start()
	id := newID()
	sv.mu.Lock()
	if len(sv.s) >= maxSessions {
		sv.mu.Unlock()
		http.Error(w, "Pseudo-Steve is busy. Try again later.", http.StatusServiceUnavailable)
		return
	}
	sv.s[id] = se
	sv.mu.Unlock()
	writeJSON(w, reply{ID: id, Text: se.output()})
}

func (sv *server) say(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "POST only", http.StatusMethodNotAllowed)
		return
	}
	var req struct {
		ID   string `json:"id"`
		Line string `json:"line"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4096)).Decode(&req); err != nil {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	if len(req.Line) > maxLine {
		req.Line = req.Line[:maxLine]
	}
	sv.mu.Lock()
	se := sv.s[req.ID]
	if se != nil {
		se.last = time.Now()
	}
	sv.mu.Unlock()
	if se == nil {
		http.Error(w, "session expired", http.StatusGone)
		return
	}
	sv.mu.Lock() // one session's state is not safe for concurrent lines
	done := se.ps.Line(req.Line)
	text := se.output()
	if done {
		delete(sv.s, req.ID)
	}
	sv.mu.Unlock()
	writeJSON(w, reply{Text: text, Done: done})
}

func serve(addr string, tree map[Atom]List, version, site string) {
	sv := &server{tree: tree, version: version, s: map[string]*session{}}
	go sv.reap()
	mux := http.NewServeMux()
	if site != "" {
		// The visual version: static files built by build-site.sh.
		mime.AddExtensionType(".wasm", "application/wasm")
		mux.Handle("/", http.FileServer(http.Dir(site)))
	} else {
		mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			if r.URL.Path != "/" {
				http.NotFound(w, r)
				return
			}
			w.Header().Set("Content-Type", "text/html; charset=utf-8")
			w.Write(indexHTML)
		})
	}
	mux.HandleFunc("/start", sv.start)
	mux.HandleFunc("/say", sv.say)
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok\n")) })
	log.Printf("Pseudo-Steve listening on %s (version %s)", addr, version)
	srv := &http.Server{Addr: addr, Handler: mux,
		ReadTimeout: 10 * time.Second, WriteTimeout: 10 * time.Second}
	log.Fatal(srv.ListenAndServe())
}
