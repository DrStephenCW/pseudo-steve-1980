//go:build !js

package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"strings"
)

func main() {
	flag.BoolVar(&strict, "strict", true, "keep the 1980 MLISP FOR/UNTIL behaviour in LOOK")
	version := flag.String("version", "jun", "program version: jun (5 rules, as in the paper) or oct (Oct 1980, rules 1-3 removed)")
	echo := flag.Bool("e", false, "echo input lines (for replaying scripts)")
	treeFile := flag.String("tree", "", "load a different TRUTH.LSP")
	httpAddr := flag.String("http", "", "serve the web version on this address, e.g. 127.0.0.1:8080")
	site := flag.String("site", "", "with -http, serve this directory (the visual version from build-site.sh) instead of the plain page")
	flag.Parse()
	src := truthLSP
	if *treeFile != "" {
		b, err := os.ReadFile(*treeFile)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		src = strings.ReplaceAll(string(b), "\r", "")
	}
	tree, err := loadTree(src)
	if err != nil {
		fmt.Fprintln(os.Stderr, "TRUTH.LSP:", err)
		os.Exit(1)
	}
	if *version != "jun" && *version != "oct" {
		fmt.Fprintln(os.Stderr, "-version must be jun or oct")
		os.Exit(2)
	}
	if *httpAddr != "" {
		serve(*httpAddr, tree, *version, *site)
		return
	}
	p := &PS{tree: tree, version: *version, echo: *echo,
		out: bufio.NewWriter(os.Stdout), in: bufio.NewScanner(os.Stdin)}
	p.Run()
}
