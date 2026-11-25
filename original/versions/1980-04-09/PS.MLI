IMMEDIATE SPECIAL L,CURRENT,SEARCH,OSEARCH;

SEARCH _ NIL;

EXPR PS();
  BEGIN NEW HIT;
    NOPRINT('RD);
    MSG(T,"[Hello, I'm Pseudo-Steve.  Type HELP for help.]",T);
    PROMPT(0);
L;  L _ GETQUEST();
    CURRENT _ 'TOP;
    OSEARCH _ SEARCH;
    SEARCH _ NIL;
    HIT _ LOOK();
    IF HIT THEN SAY(SEARCH[1]) 
    ELSE IF STRINGP(SEARCH[1])         
           THEN MSG("[I'm not sure I understood.]",T)
           ALSO SAY(SEARCH[1])
         ELSE MSG("[I didn't understand the question, sorry.]",T);
    GO L;
  END;

EXPR GETQUEST();
    BEGIN NEW L,X;
L;  MSG(T,"[Yes?] ");
    L _ LINEREAD(NIL);
    IF CONSP L[1] THEN PRINT(EVAL(L[1])) ALSO MSG(T) ALSO GO L;
    IF NUMBERP L[1] THEN EXPLAINSEARCH(SEARCH) ALSO GO L;
    IF L[1] = 'HELP THEN HELP() ALSO GO L;
    IF (L[1] = 'THANKS) |
       (L[1] = 'THANK & L[2] = 'YOU)
          THEN MSG(1,"[You're welcome!]",T,T) 
          ALSO NOPRINT('LOGOUT) 
          ALSO EXIT(NIL);
    L _ FOR NEW WORD IN L COLLECT 
          IF ~NUMBERP(WORD) & ~STRINGP(WORD) THEN
            IF X _ GET(WORD,'USAGE) THEN <X>
            ELSE <WORD> 
          ELSE <WORD>;
    RETURN L;
    END;

EXPR LOOK();
  BEGIN NEW MORE,DONE,X,Z,USED;
    Z _ EVAL(CURRENT);
X;  MORE _ NIL;
    IF LENGTH(Z) EQ 1 & X _ STRINGP(Z[1,1]) THEN DONE _ T 
    ELSE
      BEGIN
      FOR NEW ASSOCIATION IN Z DO:
        IF ASSOCIATION[1] MEMQ L 
           THEN Z _ EVAL(ASSOCIATION[2]) 
           ALSO CURRENT _ ASSOCIATION[1]
           ALSO PUSH(SEARCH,ASSOCIATION[1])
           ALSO USED _ MORE _ T 
        UNTIL MORE;                                   
      IF ~MORE THEN
        FOR NEW ASSOCIATION IN Z DO:
          IF ASSOCIATION[1] MEMQ OSEARCH 
             THEN Z _ EVAL(ASSOCIATION[2]) 
             ALSO CURRENT _ ASSOCIATION[1]
             ALSO PUSH(SEARCH,ASSOCIATION[1])
             ALSO MORE _ T 
          UNTIL MORE;                                   
      END;
    IF MORE THEN GO X
    ELSE IF X _ STRINGP(CAAR LAST(Z)) THEN PUSH(SEARCH,X);
  IF USED THEN RETURN DONE ELSE RETURN SEARCH _ NIL;
  END;

EXPR SAY(X);
  BEGIN MSG(1); PRINC(X); MSG(".",T); END;

EXPR EXPLAINSEARCH(SEARCH);
  BEGIN 
  IF NULL SEARCH THEN MSG("[No history to print.]",T) 
                 ALSO RETURN NIL;
  MSG(T,1,"[Search history:]",T);
  FOR NEW I IN REVERSE(SEARCH) DO: SPRINT(I,5);
  MSG(T);
  END;

EXPR HELP();
   \(TYPE (1264 4) (PS.HLP));

EXPR RF();
    READLIST(EXPLODE REMAINDER(DTIME(),101) @
             EXPLODE CADR MYPPN());

EXPR RD();
    EVAL <'DSKLOG, '(2360Q 4Q), RF() CONS 'QRZ>;

EXPR NOPRINT(F);
  BEGIN
    \(OUTPUT 2 NUL: (USED.NOT));  OUTC(2);
    EVAL(<F>);
    OUTC(NIL);
  END;

