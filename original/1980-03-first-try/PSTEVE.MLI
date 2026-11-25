EXPR PSTEVE();
  BEGIN NEW STORY,SCRIPT,LINE,SUBJECT,TOTALED;
    PROMPT(0);
    CLRBFI();
    MSG(T,"Hello, I'm Pseudo-Steve.",T);
    MSG(T,"Steve Willson, the 145 TA, has told me the answers to frequently",T,
          "asked questions.  Ask me a question about the class and I'll",T,
          "answer it if I can.",T);
L;  MSG(T,"Yes? [end with two carriage returns]",T);
    STORY _ NIL;
    DO:
      BEGIN
      LINE _ LINEREAD(T);
      IF LINE THEN STORY _ STORY @ LINE;
      END
    UNTIL NULL LINE;
    TOTALED _ COUNT(STORY);
    SUBJECT _ SORT(TOTALED,'SORTAUX,NIL);
    PRINC(GET(CAAR SUBJECT,'ENGLISH)); MSG(T);
    EXIT(NIL);
  END;

EXPR SORTAUX(X,Y);
    X[2] GE Y[2];

EXPR COUNT(STORY);
    BEGIN NEW TOT,Y,Z;
    FOR NEW WORD IN STORY DO:
      IF ~STRINGP(WORD) AND ~NUMBERP(WORD) THEN
        FOR NEW SCRIPT IN Z _ GET(WORD,'USAGE) DO:
            IF Y _ ASSOC(SCRIPT,TOT) THEN
                RPLACA(CDR Y,Y[2]+1.0/LENGTH(Z)+0.0)
            ELSE TOT _ <SCRIPT,1> CONS TOT;
    RETURN TOT;
    END;

EXPR DONE();
  BEGIN
  MSG("Type .save psteve to save this core image.");
  GC();
  SYSCLR(); 
  EXCISE();
  INITFN('PSTEVE);
  EXIT(NIL);
  END;
