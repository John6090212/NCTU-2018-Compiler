%{
#include <stdio.h>
#define LIST                { strncat(buf, yytext, sizeof(buf) - strlen(buf) - 1); }
#define token(t)            { LIST; if (Opt_Token) printf("<%s>\n", #t); }
#define tokenString(t, s)   { LIST; if (Opt_Token) printf("<%s:%s>\n", t, s); }
#define MAX_LINE_LENGTH 257
#define MAX_ID_LENGTH 257
int Opt_Source = 1;
int Opt_Token = 1;
int Opt_Statistic = 1;
int linenum = 1;
int i = 0;
char *temp;
char buf[MAX_LINE_LENGTH];

typedef struct node{
	char word[257];
	int num;
	struct node *next;
}Node;

Node *idlist = NULL;

%}

%s COMMENT
%%
"(" {tokenString("delim", "(");}
")" {tokenString("delim", ")");} 
"," {tokenString("delim", ",");}
";" {tokenString("delim", ";");}
"[" {tokenString("delim", "[");}
"]" {tokenString("delim", "]");}
"{" {tokenString("delim", "{");}
"}" {tokenString("delim", "}");}

"+" {token("+");}
"-" {token("-");}
"*" {token("*");}
"/" {token("/");}
"%" {token("%");}
"=" {token("=");}
"<" {token("<");}
"<=" {token("<=");}
"!=" {token("!=");}
">=" {token(">=");}
">" {token(">");}
"==" {token("==");}
"&&" {token("&&");}
"||" {token("||");}
"!" {token("!");}

"while" {tokenString("KW","while");} 
"do" {tokenString("KW","do");}
"if" {tokenString("KW","if");}
"else" {tokenString("KW","else");}
"true" {tokenString("KW","true");}
"false" {tokenString("KW","false");}
"for" {tokenString("KW","for");}
"int" {tokenString("KW","int");}
"print" {tokenString("KW","print");}
"const" {tokenString("KW","const");}
"read" {tokenString("KW","read");}
"boolean" {tokenString("KW","boolean");}
"bool" {tokenString("KW","bool");}
"void" {tokenString("KW","void");}
"float" {tokenString("KW","float");}
"double" {tokenString("KW","double");}
"string" {tokenString("KW","string");}
"continue" {tokenString("KW","continue");}
"break" {tokenString("KW","break");}
"return" {tokenString("KW","return");}

[a-zA-Z]([0-9]|[a-zA-Z])* {
	char idword[257];
	strcpy(idword,yytext);
	Node *current = idlist;
	int flag = 1;
	if(idlist == NULL){
		idlist = malloc(sizeof(Node));
		strcpy(idlist->word,idword);
		idlist->num = 1;
		idlist->next = NULL;
			
	}
	else{
		while(current != NULL){
			if(!strcmp(current->word,idword)){
				current->num++;
				flag = 0;
				break;
			}
			current = current->next;
		}
		if(flag){
			current = idlist;
			while(current->next != NULL){
				current = current->next;
			}
			current->next = malloc(sizeof(Node));
			strcpy(current->next->word,idword);
			current->next->num = 1;
			current->next->next = NULL;
			
		}
	}
	memset(idword, 0, 257);
	tokenString("id",yytext);
}        
  
0|[1-9][0-9]* {tokenString("integer",yytext);}  

[0-9][0-9]*"."[0-9][0-9]* {tokenString("float",yytext);}   

[0-9]*("."[0-9][0-9]*)?("E"|"e")("+"|"-")?[0-9][0-9]* {tokenString("scientific",yytext);}

\".*\" {
	temp = (char*)calloc(strlen(yytext)-1, sizeof(char));
    strncpy(temp, &yytext[1], strlen(yytext)-2);
	tokenString("string",temp);
} 

\n {
    LIST;
    if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
}

" "|\t {LIST;}

"/*" {BEGIN(COMMENT);}
<COMMENT>"*/" {BEGIN(INITIAL);}
<COMMENT>. {;}

\/\/[^\n]*\n {
	LIST;
    if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
}

"#pragma source on" {Opt_Source = 1;}
"#pragma source off" {Opt_Source = 0;}
"#pragma token on" {Opt_Token = 1;}
"#pragma token off" {Opt_Token = 0;}
"#pragma statistic on" {Opt_Statistic = 1;}
"#pragma statistic off" {Opt_Statistic = 0;}

. { // Unrecognized character
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

%%

int main( int argc, char **argv )
{	
	
	void print(Node *first){
		Node *current = first;
		while(current != NULL){
			printf("%s\t%d\n",current->word,current->num);
			current = current->next;
		}
	}
	
    if (argc >= 2)
    {
        yyin = fopen( argv[1], "r" );
        if ( NULL == yyin ) {
            fprintf( stderr, "Cannot open: %s\n", argv[1] );
            exit(-1);
        }
    }
    else
    {
        yyin = stdin;
    }

    yylex();

    if (Opt_Statistic)
    {
        // Print frequency table
		printf("frequencies of identifiers:\n");
		print(idlist);
    }

    exit(0);
}