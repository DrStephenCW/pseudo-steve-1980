
(DECLARE (IMMEDIATE (DECLARE (SPECIAL L CURRENT SEARCH OSEARCH))))


(SETQ SEARCH NIL)


(DEFPROP PS
 (LAMBDA NIL
  (PROG (HIT)
	(NOPRINT 'RD)
	(MSG T "[Hello, I'm Pseudo-Steve.  Type HELP for help.]" T)
	(PROMPT 0.)
      L (SETQ L (GETQUEST))
	(SETQ CURRENT 'TOP)
	(SETQ OSEARCH SEARCH)
	(SETQ SEARCH NIL)
	(SETQ HIT (LOOK))
	(COND [HIT (SAY (CAR SEARCH))]
	      [(STRINGP (CAR SEARCH))
	       (MSG "[I'm not sure I understood.]" T)
	       (SAY (CAR SEARCH))]
	      [T (MSG "[I didn't understand the question, sorry.]" T)])
	(GO L)))
 EXPR)


(DEFPROP GETQUEST
 (LAMBDA NIL
  (PROG (L X)
      L (MSG T "[Yes?] ")
	(SETQ L (LINEREAD NIL))
	(COND [(CONSP (CAR L)) (PRINT (EVAL (CAR L))) (MSG T) (GO L)])
	(COND [(NUMBERP (CAR L)) (EXPLAINSEARCH SEARCH) (GO L)])
	(COND [(EQUAL (CAR L) 'HELP) (HELP) (GO L)])
	(COND [(OR [EQUAL (CAR L) 'THANKS]
		   [AND [EQUAL (CAR L) 'THANK] [EQUAL (CADR L) 'YOU]])
	       (MSG 1. "[You're welcome!]" T T)
	       (NOPRINT 'LOGOUT)
	       (EXIT NIL)])
	(SETQ L
	 (MAPCAN
	  (FUNCTION
	   (LAMBDA (WORD)
	    (COND [(AND [NOT (NUMBERP WORD)] [NOT (STRINGP WORD)])
		   (COND [(SETQ X (GET WORD 'USAGE)) (LIST X)]
			 [T (LIST WORD)])]
		  [T (LIST WORD)])))
	  L))
	(RETURN L)))
 EXPR)


(DEFPROP LOOK
 (LAMBDA NIL
  (PROG (MORE DONE X Z USED)
	(SETQ Z (EVAL CURRENT))
      X (SETQ MORE NIL)
	(COND
	 [(AND [EQ (LENGTH Z) 1.] [SETQ X (STRINGP (CAR (CAR Z)))])
	  (SETQ DONE T)]
	 [T (PROG NIL
		  (PROG (&LST1 ASSOCIATION)
			(SETQ &LST1 Z)
		   LOOP (COND [(NULL &LST1) (RETURN NIL)])
			(SETQ ASSOCIATION (CAR &LST1))
			(SETQ &LST1 (CDR &LST1))
			(COND [(MEMQ (CAR ASSOCIATION) L)
			       (SETQ Z (EVAL (CADR ASSOCIATION)))
			       (SETQ CURRENT (CAR ASSOCIATION))
			       (SETQ SEARCH
				     (CONS (CAR ASSOCIATION) SEARCH))
			       (SETQ USED (SETQ MORE T))])
			(COND [MORE (RETURN NIL)])
			(GO LOOP))
		  (COND [(NOT MORE)
			 (PROG (&LST1 ASSOCIATION)
			       (SETQ &LST1 Z)
			  LOOP (COND [(NULL &LST1) (RETURN NIL)])
			       (SETQ ASSOCIATION (CAR &LST1))
			       (SETQ &LST1 (CDR &LST1))
			       (COND [(MEMQ (CAR ASSOCIATION) OSEARCH)
				      (SETQ Z (EVAL (CADR ASSOCIATION)))
				      (SETQ CURRENT (CAR ASSOCIATION))
				      (SETQ SEARCH
					    (CONS (CAR ASSOCIATION) SEARCH)
				       )
				      (SETQ MORE T)])
			       (COND [MORE (RETURN NIL)])
			       (GO LOOP))]))])
	(COND [MORE (GO X)]
	      [(SETQ X (STRINGP (CAAR (LAST Z))))
	       (SETQ SEARCH (CONS X SEARCH))])
	(COND [USED (RETURN DONE)] [T (RETURN (SETQ SEARCH NIL))])))
 EXPR)


(DEFPROP SAY (LAMBDA (X) (PROG NIL (MSG 1.) (PRINC X) (MSG "." T))) EXPR)


(DEFPROP EXPLAINSEARCH
 (LAMBDA (SEARCH)
  (PROG NIL
	(COND [(NULL SEARCH) (MSG "[No history to print.]" T) (RETURN NIL)]
	 )
	(MSG T 1. "[Search history:]" T)
	(MAPC (FUNCTION (LAMBDA (I) (SPRINT I 5.))) (REVERSE SEARCH))
	(MSG T)))
 EXPR)


(DEFPROP HELP (LAMBDA NIL (TYPE (1264. 4.) (PS . HLP))) EXPR)


(DEFPROP RF
 (LAMBDA NIL
  (READLIST (APPEND (EXPLODE (REMAINDER (DTIME) 101.))
		    (EXPLODE (CADR (MYPPN))))))
 EXPR)


(DEFPROP RD
 (LAMBDA NIL (EVAL (LIST 'DSKLOG '(1264. 4.) (CONS (RF) 'QRZ))))
 EXPR)


(DEFPROP NOPRINT
 (LAMBDA (F)
  (PROG NIL
	(OUTPUT 2. NUL: (USED . NOT))
	(OUTC 2.)
	(EVAL (LIST F))
	(OUTC NIL)))
 EXPR)


