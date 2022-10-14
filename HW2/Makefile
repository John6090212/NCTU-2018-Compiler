all:
	yacc -d -v yacc.y
	lex lex.l
	gcc -o parser lex.yy.c y.tab.c -ly -ll