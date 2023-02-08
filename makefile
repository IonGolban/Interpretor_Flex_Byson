output:
	yacc -d limbaj.y;
	lex limbaj.l;
	gcc lex.yy.c y.tab.c -o exe;
clean:
	rm -f lex.yy.c y.tab.c y.tab.h exe
