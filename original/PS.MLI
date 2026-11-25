IMMEDIATE SPECIAL L,CURRENT,SEARCH,OSEARCH,HELPED;

SEARCH _ NIL;

OSEARCH _ NIL;

EXPR PS();
  BEGIN NEW HIT;
    NOPRINT('RD); HELPED _ NIL;
    MSG(T,"Hello, I'm Pseudo-Steve.  Type HELP for help.",T);
    PROMPT(0);
L;  L _ GETQUEST();
    CURRENT _ 'TOP;
    SEARCH _ NIL;
    HIT _ LOOK();
    OSEARCH _ PUSH(OSEARCH, SEARCH);
    OSEARCH _ PRELIST(OSEARCH,2);
    ANALYZE(OSEARCH);
    GO L;
  END;

EXPR ANALYZE(OSEARCH); 

% RULES 1 & 2 & 3 WERE BORING -- DELETED OCT 21, 1980               %


% RULE 4: IF THE MOST RECENT ANSWER WAS A HIT, THEN
  INFER THAT THIS IS THE CORRECT ANSWER TO HIS QUESTION %
  IF CAR LAST(OSEARCH[1]) THEN SAY(OSEARCH[1,1])

% RULE 5: IF WE CAN'T FIGURE ANYTHING ELSE OUT, THEN PRINT THE 
  FAILURE MESSAGE %
  ELSE MSG(2,"I don't know the answer.",T);

EXPR GETQUEST();
    BEGIN NEW L;
L;  MSG(T,"Yes? ");
    L _ LINEREAD(NIL);
    IF CONSP L[1] THEN PRINT(EVAL(L[1])) ALSO MSG(T) ALSO GO L;
    IF L[1] = 1 THEN EXPLAINSEARCH(SEARCH) ALSO GO L;
    IF L[1] = 2 THEN DUMPOSEARCH(OSEARCH) ALSO GO L;
    IF L[1] = 'HELP THEN HELP() 
                         ALSO HELPED _ T
                         ALSO GO L;
    IF (L[1] = 'THANKS) |
       (L[1] = 'THANK & L[2] = 'YOU)
          THEN MSG(1,"You're welcome!",T,T) 
          ALSO NOPRINT('LOGOUT) 
          ALSO EXIT(NIL);
    RETURN L;
    END;

EXPR DUMPOSEARCH(OSEARCH);
  BEGIN
    IF NULL OSEARCH THEN MSG("No memory to print.",T) 
                    ALSO RETURN NIL;
    MSG(T,1,"Memory:",T);
    FOR NEW SEARCH IN OSEARCH DO:
    IF SEARCH THEN              
      BEGIN
      FOR NEW I IN REVERSE(SEARCH) DO: 
        BEGIN
          SPRINT(I,5);
          MSG(T);
        END;
      END
    ELSE MSG(T,5,"[Path is NIL]");
    MSG(T);
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
          IF KEYWORD MEMQ OSEARCH[1]
             THEN Z _ EVAL(ASSOCIATION[1]) 
             ALSO CURRENT _ KEYWORD
             ALSO PUSH(SEARCH,KEYWORD)
             ALSO OSEARCH _ XREMOVE(KEYWORD,OSEARCH)
             ALSO MORE _ T 
          UNTIL MORE;                                   
      END;
    IF MORE THEN GO X
    ELSE IF X _ STRINGP(CADAR LAST(Z)) THEN PUSH(SEARCH,X);
  SEARCH _ NCONC(SEARCH, <IF USED THEN DONE ELSE NIL>);
                                % REMEMBER IF HIT MADE %
  IF USED THEN RETURN DONE ELSE RETURN %SEARCH _%NIL;
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
   \(TYPE (1264 4 PS) (PS.HLP));

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

