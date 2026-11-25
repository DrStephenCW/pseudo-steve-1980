# Pseudo-Steve (1980)

Pseudo-Steve was a question-answering program that Stephen Willson (now
Stephen Clarke-Willson) wrote in MLISP on the UC Irvine DECsystem-10 for
ICS 199, an independent research course, in Spring 1980. The idea was
entirely Steve's. Richard Granger, who supervised the course, reviewed some
of its sessions along the way.

Steve was the TA for ICS 145, the compiler construction lab taught by Ken
Hertzler. Pseudo-Steve answered the routine questions for him: due dates,
office hours, what each assignment is. Its help text says it plainly:

> I know the answers to many of the boring questions about ICS 145 SQ 80
> that the real Steve doesn't like to answer.

It followed keywords down a hand-built knowledge tree (`TRUTH.LSP`), and it
reused the previous question's path as context, so "how about assignment two"
works after "when is assignment three due". The June 1980 version adds five
inference rules over the last two searches. For example, if two questions in
a row land on the same answer, it guesses that it misunderstood one of them.

## Run it

    cd port
    go build -o ps .
    ./ps                   # June 1980 version, five rules (as in the paper)
    ./ps -version oct      # October 1980, rules 1-3 removed
    ./ps -e < testdata/paper.in

For the web version, run `./ps -http 127.0.0.1:8080` and open that address.
See [`port/deploy/README.md`](port/deploy/README.md) for hosting it behind
nginx with systemd.

Type `help` for help, `1` to see the last search path, `2` to see the
two-search memory, and `thank you` to quit.

`go test` (or `go test -v` to see the conversation) replays the "Annotated Run of Pseudo-Steve" from the June 1980
write-up. All 24 answers match the paper word for word.

## What's here

`original/` holds the files exactly as recovered from a 1980 TOPS-10 BACKUP
tape (UCI account [2360,4]). The `.RNO.md` files are modern Markdown
renderings of the RUNOFF sources.

| File | What it is |
|---|---|
| `PS.MLI` | MLISP source, 23 Oct 1980 (latest) |
| `TRUTH.LSP` | the knowledge tree, 83 `DEFV` nodes |
| `PS.HLP`, `PS.RNH` | the HELP text |
| `PS.RNO`, `PS.MEM` | the write-up, "Pseudo-Steve", ICS 199 SQ 80 (Granger) |
| `PS.MIC`, `CPS.MIC`, `UPDATE.MIC` | build and run scripts |
| `PS.LSP`, `PS.LAP` | April 1980 Lisp translation and compiled LAP |
| `PS.EXE` | the saved executable, 31 Oct 1980 (36-bit core-dump format) |
| `*.QRZ` | eight real student sessions, 7-9 April 1980 |
| `NPS.LOG`, `PS.LOG`, `GRANGE.LOG`, `NGRANG.LOG`, `LONG.LOG`, `621.LOG` | more sessions |
| `PS1.LOG` | an April session Steve mailed to Granger for review, with Granger's comments and Steve's replies |
| `1980-03-first-try/` | March 1980 first attempt, script-based (`PSTEVE.MLI`) |
| `OLDPS/`, `versions/` | older copies, by date |

The program went through four generations:

- **April 9.** The tree was pairs of (keyword node), plus a table of
  synonyms. The student sessions were made with this version. Its tree is
  lost: the `TRUTH.LSP` saved that day has the same bytes as `PS.MLI`.
- **May 18.** Each node lists several keywords, the format kept from then on.
- **June 12.** The five inference rules described in the write-up.
- **October 23.** "RULES 1 & 2 & 3 WERE BORING -- DELETED OCT 21, 1980".

In `PS1.LOG`, Granger's review was mixed ("YUK" on one answer, "TERRIFFIC"
on another), and he asked for more sessions that tested a wider range of
English.

## About the port

`port/` is a Go transliteration of `PS.MLI`. It reads the 1980 `TRUTH.LSP`
as it is, so the answers are the ones students got.

- `LOOK` keeps an MLISP quirk: `UNTIL MORE` ends only the inner `FOR`, so
  after a match the first keyword of each later branch of the old node is
  still tried. `-strict=false` turns this off. The paper's run comes out the
  same either way.
- Punctuation and apostrophes are dropped from input, so "steve's" reads as
  STEVES. The 1980 reader would have turned `'` into QUOTE.
- In 1980, a line starting with `(` was evaluated as Lisp (a back door for
  the author). The port ignores it.
- `ps -http` serves the same program as a web page, one session per visitor.
- The 1980 program logged every session to a numbered file. That is where
  the `.QRZ` files come from. The port does not log.
- The tree is the May 18 `TRUTH.LSP`, which the October copy matches. The
  paper's tree was a little different: it knew WHATS, and this one doesn't.

The phone numbers in the tree are 1980 UC Irvine office extensions.

## Later

In 1981, teaching Lisp on the UCI DEC-20, Steve set "(PSEUDO-STEVE)" as a
homework problem, with extra credit for the memory feature.

Related repos: [ada-parser-1981](https://github.com/DrStephenCW/ada-parser-1981),
[ada-interpreter-1984](https://github.com/DrStephenCW/ada-interpreter-1984),
[f-editor-1981](https://github.com/DrStephenCW/f-editor-1981),
[spwnn-origins-1980](https://github.com/DrStephenCW/spwnn-origins-1980),
[pdp10-magtape-recovery](https://github.com/DrStephenCW/pdp10-magtape-recovery).

This recovery project was done with Claude Opus 5.5 Medium Effort guided by
Stephen Clarke-Willson.
