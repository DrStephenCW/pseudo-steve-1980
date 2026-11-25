package main

import (
	"bufio"
	"bytes"
	"os"
	"strings"
	"testing"
)

// TestPaperRun replays the "Annotated Run of Pseudo-Steve" from the
// June 1980 write-up (PS.MEM pages 4-6). testdata/paper.out was checked
// by hand against the paper: all 24 answers match.
func TestPaperRun(t *testing.T) {
	in, _ := os.ReadFile("testdata/paper.in")
	want, _ := os.ReadFile("testdata/paper.out")
	tree, err := loadTree(truthLSP)
	if err != nil {
		t.Fatal(err)
	}
	var out bytes.Buffer
	p := &PS{tree: tree, version: "jun", echo: true,
		out: bufio.NewWriter(&out), in: bufio.NewScanner(strings.NewReader(string(in)))}
	p.Run()
	t.Logf("replayed the paper's annotated run:\n%s", out.String())
	if out.String() != string(want) {
		t.Errorf("output differs from paper run:\n%s", out.String())
	}
}
