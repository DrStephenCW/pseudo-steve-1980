IMMEDIATE SPECIAL L,CURRENT,SEARCH,OSEARCH,HELPED;

SEARCH _ NIL;

EXPR PS();
  BEGIN NEW HIT;
    NOPRINT('RD); HELPED _ NIL;
    MSG(T,"Hello, I'm Pseudo-Steve.  Type HELP for help.",T);
    PROMPT(0);
L;  L _ GETQUEST();
    IF L[1] = 'NO' THEN SEARCH _ NIL      
                   ALSO POP(L);
    IF L = '(LISTEN TO ME) THEN LISTENUP() ALSO GO L;
    CURRENT _ 'TOP;
    OSEARCH _ SEARCH;
    SEARCH _ NIL;
    HIT _ LOOK();
    IF HIT THEN SAY(SEARCH[1]) 
    ELSE IF STRINGP(SEARCH[1])         
           THEN MSG("Uh,")
           ALSO SAY(SEARCH[1])
         ELSE MSG("I can't figure out the answer, sorry, next question!",T);
    GO L;
  END;

EXPR GETQUEST();
    BEGIN NEW L;
L;  MSG(T,"Yes? ");
    L _ LINEREAD(NIL);
    IF CONSP L[1] THEN PRINT(EVAL(L[1])) ALSO MSG(T) ALSO GO L;
    IF NUMBERP L[1] THEN EXPLAINSEARCH(SEARCH) ALSO GO L;
    IF L[1] = 'HELP THEN IF NULL HELPED THEN HELP() 
                                        ALSO HELPED _ T
                                        ALSO GO L 
                         ELSE MSG("Sorry.",T) 
                         ALSO GO L 
    ELSE NIL;
    IF (L[1] = 'THANKS) |
       (L[1] = 'THANK & L[2] = 'YOU)
          THEN MSG(1,"You're welcome!",T,T) 
          ALSO NOPRINT('LOGOUT) 
          ALSO EXIT(NIL);
    RETURN L;
    END;

EXPR LOOK();
  BEGIN NEW MORE,DONE,X,Z,USED;
    Z _ EVAL(CURRENT);
X;  MORE _ NIL;
    IF LENGTH(Z) EQ 1 & X _ STRINGP(Z[1,2]) THEN DONE _ T 
    ELSE
      BEGIN
      FOR NEW ASSOCIATION IN Z DO:
       FOR NEW KEYWORD IN CDR ASSOCIATION DO:
        IF KEYWORD MEMQ L 
           THEN Z _ EVAL(ASSOCIATION[1]) 
           ALSO CURRENT _ KEYWORD
           ALSO PUSH(SEARCH,KEYWORD)
           ALSO USED _ MORE _ T 
           ALSO L _ XREMOVE(KEYWORD,L) 
        UNTIL MORE;                                   
      IF ~MORE THEN
        FOR NEW ASSOCIATION IN Z DO:
         FOR NEW KEYWORD IN CDR ASSOCIATION DO:
          IF KEYWORD MEMQ OSEARCH 
             THEN Z _ EVAL(ASSOCIATION[1]) 
             ALSO CURRENT _ KEYWORD
             ALSO PUSH(SEARCH,KEYWORD)
             ALSO OSEARCH _ XREMOVE(KEYWORD,OSEARCH)
             ALSO MORE _ T 
          UNTIL MORE;                                   
      END;
    IF MORE THEN GO X
    ELSE IF X _ STRINGP(CADAR LAST(Z)) THEN PUSH(SEARCH,X);
  IF USED THEN RETURN DONE ELSE RETURN SEARCH _ NIL;
  END;

EXPR XREMOVE(X,L);
  BEGIN NEW FLAG;
  RETURN
    FOR NEW I IN L COLLECT
      IF X EQ I THEN IF FLAG THEN <I>
                             ELSE FLAG _ T
                             ALSO NIL
                     ELSE <I>;
  END;

EXPR SAY(X);
  BEGIN MSG(1); PRINC(X); MSG(".",T); END;

EXPR EXPLAINSEARCH(SEARCH);
  BEGIN 
  IF NULL SEARCH THEN MSG("No history to print.",T) 
                 ALSO RETURN NIL;
  MSG(T,1,"Search history:",T);
  FOR NEW I IN REVERSE(SEARCH) DO: SPRINT(I,5);
  MSG(T);
  END;

EXPR HELP();
   \(TYPE (1264 4) (PS.HLP));

EXPR RF();
    READLIST(EXPLODE REMAINDER(DTIME(),101) @
             EXPLODE CADR MYPPN());

EXPR RD();
    EVAL <'DSKLOG, '(2360Q 4Q), RF() CONS 'LOG>;

EXPR NOPRINT(F);
  BEGIN
    \(OUTPUT 2 NUL: (USED.NOT));  OUTC(2);
    EVAL(<F>);
    OUTC(NIL);
  END;

EXPR RESTORE();         % use: (dskout (truth.lsp) (restore)) %
    FOR NEW I IN ('TOP CONS TREELIST(TOP)) DO: RESFUNC(I);
  
EXPR RESFUNC(X);
  BEGIN NEW Y;
  Y _ GET(X,'VALUE);
  MSG("(DEFV ",X,T);
  SPRINT(CDR Y,2);
  MSG(")",T,T);
  END;

EXPR TREE(ROOT,LEVEL);
  BEGIN 
  FOR NEW ASSOCIATION IN ROOT DO:
    BEGIN
      SPRINT(ASSOCIATION[1],LEVEL);
      TREE(EVAL(ASSOCIATION[1]),LEVEL+5);
    END;
  END;

EXPR TREELIST(ROOT);
  FOR NEW ASSOCIATION IN ROOT COLLECT
    IF ASSOCIATION[1] THEN
      <ASSOCIATION[1]> @ FLATTEN TREELIST(EVAL(ASSOCIATION[1]));

EXPR LISTENUP();
    BEGIN NEW L, CHANGED;
    MSG(T,"Ok, what's up?",T);
L;  MSG("! ");
    L _ LINEREAD(NIL);
    CHANGED _ NIL;
    IF L[1] = 'DONE THEN RETURN NIL;
    DO:
    IF ~LOOK() THEN
        BEGIN
          INSERTNODE(L[1]);
          CHANGED _ T;
        END
    UNTIL NULL L;
    IF ~CHANGED THEN MSG(T,"That path is in use!  Try again.",T);
    GO L;
    END;
    
EXPR INSERTNODE(NODE);
  BEGIN END;
