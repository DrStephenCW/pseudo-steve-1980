EXPR KSTEVE();
  BEGIN NEW STORY,SCRIPT,LINE,SUBJECT,TOTALED;
    PROMPT(0);
    CLRBFI();
L;  MSG(T,"End question with two <cr>'s.",T);
    STORY _ NIL;
    DO:
      BEGIN
      LINE _ LINEREAD(T);
      IF LINE THEN STORY _ STORY @ LINE;
      END
    UNTIL NULL LINE;
A;  MSG(T,"Answer token? ");
    SCRIPT _ LINEREAD(NIL);
    IF CAR SCRIPT = 'DONE THEN PROMPT(42) ALSO RETURN NIL;
    IF CAR SCRIPT = 'IGNORE THEN GO L;
    FOR NEW J IN SCRIPT DO:
      BEGIN
      IF ~MEMQ(J,KNOWNSCRIPTS) THEN
        BEGIN NEW X;
        PUSH(KNOWNSCRIPTS,J);
        FOR NEW I IN STORY DO: PUTSCRIPT(I,J);
        MSG(T,"Enter answer string:",T);
        X _ LINEREAD(NIL);
        PUT(J,CAR X,'ENGLISH);
        END
      ELSE 
        BEGIN NEW Q;
R;      MSG(T,J," is an already used answer token.",T);
        MSG("Do you want to use it [Y OR N]? "); Q _ LINEREAD(NIL);
        IF Q[1] EQ 'Y THEN
          FOR NEW I IN STORY DO: PUTSCRIPT(I,J)
        ELSE IF Q[1] EQ 'N THEN MSG(T,J," ignored.",T) ALSO RETURN NIL 
        ELSE GO R;
        END
      END;
    GO L;
  END;

EXPR PUTSCRIPT(WORD,SCRIPT); 
  BEGIN NEW X,Y;
    X _ GET(WORD,'USAGE);
    IF ~Y _ MEMQ(SCRIPT,X) THEN PUT(WORD,SCRIPT CONS X,'USAGE);
   END;

FEXPR SAVEWORLD(FILE);
    EVAL<'DSKOUT,FILE[1],'(PENG),'(SKNOWN),'(PWORLD)>;

EXPR PENG();
  FOR NEW I IN KNOWNSCRIPTS DO:
    BEGIN
      MSG("(DEFPROP ",I,T);
      SPRINT(GET(I,'ENGLISH),5);
      MSG(T,"ENGLISH)",T);
    END;

EXPR SKNOWN();
  BEGIN 
    MSG("(DEFPROP KNOWNSCRIPTS",T);
    SPRINT(KNOWNSCRIPTS,5);
    MSG(T,"VALUE)",T);
  END;

EXPR PWORLD();
    MAPATOMS('PUSAGE);

EXPR PUSAGE(WORD);
    BEGIN NEW X;
    X _ GET(WORD,'USAGE);
    IF NULL X THEN RETURN();
    MSG("(DEFPROP ",WORD,T);
    SPRINT(X,5);
    MSG(T,"USAGE)",T);
    END;

EXPR DONE();
  BEGIN
    EXCISE();
    SYSCLR();
    MSG(T,"Calling Garbage Collector...",T);
    GC();
    MSG(T,"Type ..SAVE <NAME> to save this core image.");
    EXIT(NIL);
  END;
