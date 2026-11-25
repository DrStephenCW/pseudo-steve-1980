# First try, March 1980

The first Pseudo-Steve was built on the New U story classifier that Steve
wrote earlier in 1980 (see
[spwnn-origins-1980](https://github.com/DrStephenCW/spwnn-origins-1980)).
`PSTEVE.MLI` is the classifier's main loop, with "Story?" turned into
"Yes?". It scores a question against the words each "script" was trained
on and prints that script's stored answer. `KSTEVE.MLI` trained it on
course questions, and `PS.LSP` is a tiny saved example of that training.

The classifier's other files (`L.MLI`, `LGEN.MLI`, `KNOWN.MLI`) and its word
memory are in spwnn-origins-1980. Within weeks Steve replaced this approach
with the hand-built keyword tree in `TRUTH.LSP`.
