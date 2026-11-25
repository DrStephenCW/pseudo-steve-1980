// Pseudo-Steve: a Go transliteration of PS.MLI (Stephen Willson, UC Irvine,
// ICS 199 SQ 80, for Richard Granger). The original was MLISP on TOPS-10.
//
// The knowledge tree is read straight from the 1980 TRUTH.LSP (DEFV forms),
// so the answers are exactly the ones students got in 1980.
//
// Two program versions are kept:
//
//	-version jun  (default) PS.MLI of 12 Jun 1980, the one described in the
//	              write-up PS.RNO, with all five inference rules.
//	-version oct  PS.MLI of 23 Oct 1980, after "RULES 1 & 2 & 3 WERE BORING
//	              -- DELETED OCT 21, 1980".
package main

import (
	"bufio"
	_ "embed"
	"flag"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
	"unicode"
)

//go:embed TRUTH.LSP
var truthLSP string

//go:embed PS.HLP
var psHLP string

// ---------------------------------------------------------------------------
// A tiny Lisp value model: just enough for the DEFV tree.

type Atom string // symbols, upper case
type Str string  // string literals
type Num int     // fixnums such as the 1. 2. 3. 4. keywords
type List []any  // lists; nil/empty is NIL

func isNil(v any) bool {
	switch x := v.(type) {
	case nil:
		return true
	case Atom:
		return x == "NIL"
	case List:
		return len(x) == 0
	}
	return false
}

// eq is Lisp EQ/MEMQ on atoms and fixnums.
func eq(a, b any) bool {
	switch x := a.(type) {
	case Atom:
		y, ok := b.(Atom)
		return ok && x == y
	case Num:
		y, ok := b.(Num)
		return ok && x == y
	}
	return false
}

func memq(x any, l List) bool {
	for _, e := range l {
		if eq(x, e) {
			return true
		}
	}
	return false
}

// ---------------------------------------------------------------------------
// Reader for TRUTH.LSP

type reader struct {
	s   string
	pos int
}

func (r *reader) skip() {
	for r.pos < len(r.s) {
		c := r.s[r.pos]
		if c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' {
			r.pos++
		} else {
			return
		}
	}
}

func (r *reader) read() (any, error) {
	r.skip()
	if r.pos >= len(r.s) {
		return nil, io.EOF
	}
	switch c := r.s[r.pos]; c {
	case '(':
		r.pos++
		l := List{}
		for {
			r.skip()
			if r.pos >= len(r.s) {
				return nil, fmt.Errorf("unexpected EOF in list")
			}
			if r.s[r.pos] == ')' {
				r.pos++
				return l, nil
			}
			v, err := r.read()
			if err != nil {
				return nil, err
			}
			l = append(l, v)
		}
	case ')':
		return nil, fmt.Errorf("unexpected ) at %d", r.pos)
	case '"':
		r.pos++
		start := r.pos
		for r.pos < len(r.s) && r.s[r.pos] != '"' {
			r.pos++
		}
		v := Str(r.s[start:r.pos])
		r.pos++
		return v, nil
	default:
		start := r.pos
		for r.pos < len(r.s) && !strings.ContainsRune(" \t\n\r\f()\"", rune(r.s[r.pos])) {
			r.pos++
		}
		return atomOrNum(r.s[start:r.pos]), nil
	}
}

func atomOrNum(tok string) any {
	t := strings.TrimSuffix(tok, ".") // "1." is decimal 1 in UCI Lisp
	if n, err := strconv.Atoi(t); err == nil {
		return Num(n)
	}
	return Atom(strings.ToUpper(tok))
}

// loadTree evaluates the DEFV forms. As in Lisp, a later DEFV of the same
// node replaces the earlier one (TRUTH.LSP has a few duplicates).
func loadTree(src string) (map[Atom]List, error) {
	tree := map[Atom]List{}
	r := &reader{s: src}
	for {
		v, err := r.read()
		if err == io.EOF {
			return tree, nil
		}
		if err != nil {
			return nil, err
		}
		f, ok := v.(List)
		if !ok || len(f) != 3 || !eq(f[0], Atom("DEFV")) {
			return nil, fmt.Errorf("unexpected form %v", v)
		}
		val, _ := f[2].(List)
		tree[f[1].(Atom)] = val
	}
}

// ---------------------------------------------------------------------------
// The program (names follow PS.MLI)

type PS struct {
	tree    map[Atom]List
	version string
	out     *bufio.Writer
	in      *bufio.Scanner
	echo    bool

	L       List   // the question (SPECIAL L)
	current Atom   // CURRENT
	search  List   // SEARCH: stack of keywords, then answer string, then hit flag
	osearch []List // OSEARCH: the last two SEARCHes, newest first
}

func (p *PS) eval(sym Atom) List { return p.tree[sym] }

// msg mimics UCI Lisp MSG: T = newline, a number = that many spaces.
func (p *PS) msg(args ...any) {
	for _, a := range args {
		switch x := a.(type) {
		case bool:
			p.out.WriteString("\n")
		case int:
			p.out.WriteString(strings.Repeat(" ", x))
		case string:
			p.out.WriteString(x)
		case Str:
			p.out.WriteString(string(x))
		}
	}
	p.out.Flush()
}

const T = true

func (p *PS) Run() {
	p.msg(T, "Hello, I'm Pseudo-Steve.  Type HELP for help.", T)
	for {
		l, ok := p.getquest()
		if !ok {
			return
		}
		p.L = l
		p.current = "TOP"
		p.search = nil
		p.look()
		p.osearch = append([]List{p.search}, p.osearch...) // PUSH
		if len(p.osearch) > 2 {                            // PRELIST(OSEARCH,2)
			p.osearch = p.osearch[:2]
		}
		p.analyze()
	}
}

// helpers for the OSEARCH[i,1] and CAR LAST(OSEARCH[i]) idioms
func (p *PS) os(i int) List {
	if i < len(p.osearch) {
		return p.osearch[i]
	}
	return nil
}
func first(l List) any {
	if len(l) == 0 {
		return nil
	}
	return l[0]
}
func lastTrue(l List) bool { return len(l) > 0 && l[len(l)-1] == true }
func sameAnswer(a, b List) bool {
	x, ok1 := first(a).(Str)
	y, ok2 := first(b).(Str)
	return ok1 && ok2 && x == y
}

func (p *PS) analyze() {
	o1, o2 := p.os(0), p.os(1)
	if p.version == "oct" {
		// RULES 1 & 2 & 3 WERE BORING -- DELETED OCT 21, 1980
		if lastTrue(o1) { // RULE 4
			p.say(first(o1))
		} else { // RULE 5
			p.msg(2, "I don't know the answer.", T)
		}
		return
	}
	switch {
	case sameAnswer(o1, o2) && lastTrue(o1) && lastTrue(o2): // RULE 1
		p.msg(2, "Either I just responded to that or", T)
		p.msg(2, "we're not communicating here.", T)
		p.msg(2, "Perhaps you should try using different words", T)
		p.msg(2, "that have meanings I can separate easier.", T)
	case sameAnswer(o1, o2) && !lastTrue(o1) && !lastTrue(o2): // RULE 2
		p.msg(2, "I think you are leaving out some contextual information", T)
		p.msg(2, "that I should know in order to figure out what you mean.", T)
		p.msg(2, "Try giving me more context.", T)
	case !lastTrue(o1): // RULE 3
		p.msg(2, "Maybe it will help if I tell you that", T)
		p.say(first(o1))
	case lastTrue(o1): // RULE 4
		p.say(first(o1))
	default: // RULE 5 (unreachable, as in the original)
		p.msg(2, "I can't figure out the answer, sorry, next question!", T)
	}
}

// lineread approximates UCI Lisp LINEREAD: words become upper-case atoms,
// digits become numbers. Punctuation is dropped (the 1980 reader would have
// turned ' into QUOTE and choked on some marks; the help text asks users
// not to type any).
func lineread(s string) List {
	s = strings.ReplaceAll(s, "'", "")
	f := strings.FieldsFunc(s, func(r rune) bool {
		return !(unicode.IsLetter(r) || unicode.IsDigit(r) || r == '-' || r == '(' || r == ')')
	})
	l := List{}
	for _, w := range f {
		l = append(l, atomOrNum(w))
	}
	return l
}

func (p *PS) getquest() (List, bool) {
	for {
		p.msg(T, "Yes? ")
		if !p.in.Scan() {
			p.msg(T)
			return nil, false
		}
		line := p.in.Text()
		if p.echo {
			p.msg(line, T)
		}
		if strings.HasPrefix(strings.TrimSpace(line), "(") {
			// CONSP L[1]: the original EVALed it as Lisp (a back door for
			// the author). There is no Lisp here.
			p.msg("[no Lisp in this port]", T, T)
			continue
		}
		l := lineread(line)
		if len(l) == 0 {
			l = List{} // LINEREAD would wait for more input; treat as empty
		}
		switch {
		case len(l) > 0 && eq(l[0], Num(1)):
			p.explainsearch()
			continue
		case len(l) > 0 && eq(l[0], Num(2)):
			p.dumposearch()
			continue
		case len(l) > 0 && eq(l[0], Atom("HELP")):
			p.help()
			continue
		case len(l) > 0 && (eq(l[0], Atom("THANKS")) ||
			(eq(l[0], Atom("THANK")) && len(l) > 1 && eq(l[1], Atom("YOU")))):
			p.msg(1, "You're welcome!", T, T)
			return nil, false // NOPRINT('LOGOUT) ALSO EXIT(NIL)
		}
		return l, true
	}
}

var helped bool

func (p *PS) help() {
	if p.version == "jun" && helped {
		p.msg("Sorry.", T)
		return
	}
	helped = true
	p.msg(T, psHLP)
}

// xremove removes the first occurrence of x from l.
func xremove(x any, l List) List {
	out := List{}
	done := false
	for _, e := range l {
		if !done && eq(x, e) {
			done = true
			continue
		}
		out = append(out, e)
	}
	return out
}

// look walks the tree from CURRENT. Keywords in the question are tried
// first; failing that, keywords on the previous search path ("context").
//
// MLISP quirk kept on purpose: the UNTIL MORE belongs to the inner FOR only.
// After a match the outer FOR keeps going over the *old* node's remaining
// associations, and since UNTIL is tested after the body, the first keyword
// of each one is still tried once. (-strict=false turns this off.)
func (p *PS) look() {
	var more, done, used bool
	z := p.eval(p.current)
	for {
		more = false
		if len(z) == 1 && len(z[0].(List)) > 1 {
			if _, ok := z[0].(List)[1].(Str); ok {
				done = true
			}
		}
		if !done {
			for _, a := range z {
				assoc := a.(List)
				for _, kw := range assoc[1:] {
					if memq(kw, p.L) {
						z = p.eval(assoc[0].(Atom))
						p.current = kw.(Atom)
						p.search = append(List{kw}, p.search...)
						used, more = true, true
						p.L = xremove(kw, p.L)
					}
					if more {
						break
					}
				}
				if more && !*quirk {
					break
				}
			}
			if !more {
				prev := p.os(0)
				for _, a := range z {
					assoc := a.(List)
					for _, kw := range assoc[1:] {
						if memq(kw, prev) {
							z = p.eval(assoc[0].(Atom))
							p.current = kw.(Atom)
							p.search = append(List{kw}, p.search...)
							// OSEARCH _ XREMOVE(KEYWORD,OSEARCH): a no-op in
							// 1980 (OSEARCH is a list of lists), so omitted.
							more = true
						}
						if more {
							break
						}
					}
					if more && !*quirk {
						break
					}
				}
			}
		}
		if !more {
			break
		}
	}
	// IF X _ STRINGP(CADAR LAST(Z)) THEN PUSH(SEARCH,X)
	if len(z) > 0 {
		if la := z[len(z)-1].(List); len(la) > 1 {
			if s, ok := la[1].(Str); ok {
				p.search = append(List{s}, p.search...)
			}
		}
	}
	// SEARCH _ NCONC(SEARCH, <IF USED THEN DONE ELSE NIL>)
	p.search = append(p.search, used && done)
}

func (p *PS) say(x any) {
	p.msg(1)
	if s, ok := x.(Str); ok {
		p.msg(s)
	} else if x != nil {
		p.msg(fmt.Sprint(x))
	} else {
		p.msg("NIL")
	}
	p.msg(".", T)
}

func sprint(x any) string {
	switch v := x.(type) {
	case Str:
		return `"` + string(v) + `"`
	case bool:
		if v {
			return "T"
		}
		return "NIL"
	case nil:
		return "NIL"
	}
	return fmt.Sprint(x)
}

func (p *PS) explainsearch() {
	if len(p.search) == 0 {
		p.msg("No history to print.", T)
		return
	}
	p.msg(T, 1, "Search history:", T)
	for i := len(p.search) - 1; i >= 0; i-- {
		p.msg(5, sprint(p.search[i]), T)
	}
	p.msg(T)
}

func (p *PS) dumposearch() {
	if len(p.osearch) == 0 {
		p.msg("No memory to print.", T)
		return
	}
	p.msg(T, 1, "Memory:", T)
	for _, s := range p.osearch {
		if len(s) > 0 {
			for i := len(s) - 1; i >= 0; i-- {
				p.msg(5, sprint(s[i]), T)
			}
		} else {
			p.msg(T, 5, "[Path is NIL]")
		}
		p.msg(T)
	}
}

var quirk = flag.Bool("strict", true, "keep the 1980 MLISP FOR/UNTIL behaviour in LOOK")

func main() {
	version := flag.String("version", "jun", "program version: jun (5 rules, as in the paper) or oct (Oct 1980, rules 1-3 removed)")
	echo := flag.Bool("e", false, "echo input lines (for replaying scripts)")
	treeFile := flag.String("tree", "", "load a different TRUTH.LSP")
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
	p := &PS{tree: tree, version: *version, echo: *echo,
		out: bufio.NewWriter(os.Stdout), in: bufio.NewScanner(os.Stdin)}
	p.Run()
}
