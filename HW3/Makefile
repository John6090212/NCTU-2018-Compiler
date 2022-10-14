all:
	yacc -d -v parser.y
	lex lex.l
	gcc -o parser lex.yy.c y.tab.c main.c structure.c -lfl

