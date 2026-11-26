//go:build js && wasm

package main

// The visual version: the same program compiled to WebAssembly, with a
// trace of every search for the page to draw. See site/.

import (
	"bufio"
	"bytes"
	"encoding/json"
	"syscall/js"
)

type node struct {
	Name     string   `json:"name"`
	Text     string   `json:"text,omitempty"` // the NIL branch: answer or hint
	Branches []branch `json:"branches,omitempty"`
}

type branch struct {
	Keywords []string `json:"keywords"`
	Child    *node    `json:"child"`
}

func buildNode(tree map[Atom]List, name Atom, depth int) *node {
	n := &node{Name: string(name)}
	if depth > 12 {
		return n
	}
	for _, a := range tree[name] {
		assoc := a.(List)
		if isNil(assoc[0]) {
			if len(assoc) > 1 {
				if s, ok := assoc[1].(Str); ok {
					n.Text = string(s)
				}
			}
			continue
		}
		kws := []string{}
		for _, k := range assoc[1:] {
			kws = append(kws, sprint(k))
		}
		n.Branches = append(n.Branches, branch{kws, buildNode(tree, assoc[0].(Atom), depth+1)})
	}
	return n
}

type memo struct {
	Path   []string `json:"path"`
	Answer string   `json:"answer"`
	Hit    bool     `json:"hit"`
}

func memory(p *PS) []memo {
	out := []memo{}
	for _, s := range p.osearch {
		m := memo{Path: []string{}}
		for i := len(s) - 1; i >= 0; i-- {
			switch v := s[i].(type) {
			case Atom, Num:
				m.Path = append(m.Path, sprint(v))
			case Str:
				m.Answer = string(v)
			}
		}
		m.Hit = lastTrue(s)
		out = append(out, m)
	}
	return out
}

var (
	tree map[Atom]List
	cur  *PS
	buf  bytes.Buffer
)

func output() string {
	cur.out.Flush()
	t := buf.String()
	buf.Reset()
	return t
}

func jsonValue(v any) any {
	b, _ := json.Marshal(v)
	return string(b)
}

func main() {
	var err error
	tree, err = loadTree(truthLSP)
	if err != nil {
		panic(err)
	}
	js.Global().Set("psStart", js.FuncOf(func(this js.Value, args []js.Value) any {
		v := "jun"
		if len(args) > 0 && args[0].String() == "oct" {
			v = "oct"
		}
		buf.Reset()
		cur = &PS{tree: tree, version: v, out: bufio.NewWriter(&buf), trace: &Trace{}, tidy: true}
		cur.Start()
		return jsonValue(map[string]any{
			"text": output(),
			"tree": buildNode(tree, "TOP", 0),
			"help": psHLP,
		})
	}))
	js.Global().Set("psLine", js.FuncOf(func(this js.Value, args []js.Value) any {
		if cur == nil || len(args) == 0 {
			return nil
		}
		line := args[0].String()
		if len(line) > 500 {
			line = line[:500]
		}
		done := cur.Line(line)
		return jsonValue(map[string]any{
			"text":   output(),
			"done":   done,
			"trace":  cur.trace,
			"memory": memory(cur),
		})
	}))
	js.Global().Call("psReady")
	select {}
}
