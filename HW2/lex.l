%{
#include "y.tab.h"

#define MAX_LINE_LENGTH 257
#define MAX_ID_LENGTH 257
#define MAX_STRING_LENGTH 257
#define LIST                strlcat(buf, yytext, MAX_LINE_LENGTH)
#define token(t)            {LIST; if (Opt_Token) printf("<%s>\n", #t);}
#define tokenInteger(t, i)  {LIST; if (Opt_Token) printf("<%s:%d>\n", t, i);}
#define tokenString(t, s)   {LIST; if (Opt_Token) printf("<%s:%s>\n", t, s);}
int Opt_Source = 1;
int Opt_Token = 1;
int linenum = 1;
int Last_State = 0;
char buf[MAX_LINE_LENGTH];
char strContent[MAX_STRING_LENGTH];

%}

%x PRAGMA
%x SOURCE
%x TOKEN
%x STATISTIC
%x OTHER
%x STR
%x STR_ESCAPE
%x COMMENT

%%
<INITIAL>[\t ]+	{
		LIST;
	}
^#pragma[\t ]+	{
		LIST;
		BEGIN PRAGMA;
	}
<PRAGMA>"source"[\t ]+	{
		LIST;
		BEGIN SOURCE;
	}
<PRAGMA>"token"[\t ]+	{
		LIST;
		BEGIN TOKEN;
	}
<PRAGMA>"statistic"[\t ]+	{
		LIST;
		BEGIN STATISTIC;
	}

<SOURCE>"on"[\t ]*	{
		LIST;
		Opt_Source = 1;
		BEGIN OTHER;
	}
<SOURCE>"off"[\t ]*	{
		LIST;
		Opt_Source = 0;
		BEGIN OTHER;
	}

<SOURCE>[^\t ]	{
		//printf("Error at source line %d: %s\n",linenum, yytext);
                  fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);
        exit(1);
	}
<TOKEN>"on"[\t ]*	{
		LIST;
		Opt_Token = 1;
		BEGIN OTHER;
	}
<TOKEN>"off"[\t ]*	{
		LIST;
		Opt_Token = 0;
		BEGIN OTHER;
	}

<TOKEN>[^\t ]	{
                 fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);
        exit(1);
	}

<STATISTIC>"on"[\t ]*	{
		LIST;
		BEGIN OTHER;
	}
<STATISTIC>"off"[\t ]*	{
		LIST;
		BEGIN OTHER;
	}

<STATISTIC>[^\t ]	{
                 fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);
        exit(1);
	}
<OTHER>\/\/[^\n]*	{
		LIST;
		
	}
<OTHER>"/*"	{
		LIST;
        Last_State = OTHER;
		BEGIN COMMENT;
	}

<OTHER>\n		{
		LIST;
  	      if (Opt_Source)
  	        printf("%d:%s\n", linenum, buf);
  	      linenum++;
  	      buf[0] = '\0';
		  BEGIN INITIAL;
	}

<OTHER>[^\n]		{
                  fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);
                exit(1);

	}

<PRAGMA>[^\t ]		{
                  fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);
                exit(1);

	}
"("	{
		tokenString("delim", "(");
		return LEFT_parentheses;
	}
")"	{
		tokenString("delim", ")");
		return RIGHT_parentheses;
	}
","	{
		tokenString("delim", ",");
		return COMMA;
	}
";"	{
		tokenString("delim", ";");
		return SEMICOLON;
	}
"["	{
		tokenString("delim", "[");
		return LEFT_square_brackets;
	}
"]"	{
		tokenString("delim", "]");
		return RIGHT_square_brackets;
	}
"{"	{
		tokenString("delim", "{");
		return LEFT_curly_brackets;
	}
"}"	{
		tokenString("delim", "}");
		return RIGHT_curly_brackets;
	}
"+"	{
		token("+");
		return PLUS;
	}
"-"	{
		token("-");
		return MINUS;
	}
"*"	{
		token("*");
		return MULTIPLY;
	}
"/"	{
		token("/");
		return DIVIDE;
	}
"%"	{
		token("%");
		return MODULO;
	}
"="	{
		token("=");
		return ASSIGN;
	}
"<"	{
		token("<");
		return LESS;
	}
"<="	{
		token("<=");
		return LESS_or_EQUAL;
	}
"!="	{
		token("!=");
		return NOTEQUAL;
	}
">="	{
		token(">=");
		return GREATER_or_EQUAL;
	}
">"	{
		token(">");
		return GREATER;
	}
"=="	{
		token("==");
		return EQUAL;
	}
"&&"	{
		token("&&");
		return AND;
	}
"||"	{
		token("||");
		return OR;
	}
"!"	{
		token("!");
		return NOT;
	}
read {tokenString("KW", yytext); return READ;};
boolean {tokenString("KW", yytext); return BOOLEAN;};
while {tokenString("KW", yytext); return WHILE;};
do {tokenString("KW", yytext); return DO;};
if {tokenString("KW", yytext); return IF;};
else {tokenString("KW", yytext); return ELSE;};
true {tokenString("KW", yytext); return TRUE;}; 
false {tokenString("KW", yytext); return FALSE;}; 
for {tokenString("KW", yytext); return FOR;}; 
print {tokenString("KW", yytext); return PRINT;};
continue {tokenString("KW", yytext); return CONTINUE;}; 
break {tokenString("KW", yytext); return BREAK;}; 
return	{
		tokenString("KW", yytext);
		return RETURN;
	}
int {tokenString("KW", yytext); return INT;};
double {tokenString("KW", yytext); return DOUBLE;};
float {tokenString("KW", yytext); return FLOAT;};
string {tokenString("KW", yytext); return STRING;};
bool {tokenString("KW", yytext); return BOOL;};
const {tokenString("KW", yytext); return CONST;};
void {tokenString("KW", yytext); return VOID;};

0 |
[1-9][0-9]* {
		tokenString("integer", yytext);
		return INT_constant;
	}
[0-9]+\.[0-9]+	{
		tokenString("float", yytext);
		return FLOAT_constant;
	}

([0-9]+|([0-9]*\.[0-9]+))([eE][-+]?[0-9]+)	{
		tokenString("scientific", yytext);
		return SCIENTIFIC_constant;
	}
"\""	{ 
		LIST;
                strContent[0] = '\0';
		BEGIN STR;
	}
<STR>"\\"	{
		LIST;
		BEGIN STR_ESCAPE;
	}
<STR_ESCAPE>\"	{
		LIST;
		strlcat (strContent, "\"", MAX_STRING_LENGTH);
		BEGIN STR;
	}
<STR_ESCAPE>n	{
		LIST;
		strlcat( strContent, "\\n", MAX_STRING_LENGTH);
		BEGIN STR;
	}
<STR_ESCAPE>t	{
		LIST;
		strlcat( strContent, "\\t", MAX_STRING_LENGTH);
		BEGIN STR;
	}
<STR_ESCAPE>\\	{
		LIST;
		strlcat( strContent, "\\", MAX_STRING_LENGTH);
		BEGIN STR;
	}
<STR_ESCAPE>\n  {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}
<STR_ESCAPE>[^\"nt\\]	{
		LIST;
		strlcat( strContent, "\\", MAX_STRING_LENGTH);
		strlcat( strContent, yytext, MAX_STRING_LENGTH);
		BEGIN STR;
	}
<STR>"\n"	{
                 fprintf(stderr,"Error at line %d: %s\n",linenum,yytext);
		exit(1);
	}

<STR>\"	{
		tokenString("string", strContent);
		BEGIN INITIAL;
		return STRING_constant;
		
	}
<STR>[^\\\n\"]	{
		LIST;
		strlcat( strContent, yytext, MAX_STRING_LENGTH);
	}

"/*"	{
		LIST;
        Last_State = INITIAL;
		BEGIN COMMENT;
	}
<COMMENT>"\n"	{
		LIST;
		if(Last_State == OTHER)Last_State = INITIAL;
		if (Opt_Source)
  	        printf("%d:%s\n", linenum, buf);
		linenum++;
                buf[0] = '\0';
	}

			
<COMMENT>.	{
		LIST;
	}

<COMMENT>"*/"	{
		LIST;
		BEGIN Last_State;
	}

\/\/.*	{
		LIST;
	}

\n	{
  	      LIST;
  	      if (Opt_Source)
  	        printf("%d:%s\n", linenum, buf);
  	      linenum++;
  	      buf[0] = '\0';
        }

[a-zA-Z_][a-zA-Z0-9_]{0,255}	{
		tokenString("id",yytext);
		return ID;
	}

.	{
		//printf("Error at wee line %d: %s\n",linenum, yytext);
                 fprintf(stderr,"Error at line %d: %s\n",linenum, yytext);
		exit(1);
	}
%%
			
