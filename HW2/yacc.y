%{
#include <stdio.h>
#include <stdlib.h>

extern int linenum;             /* declared in lex.l */
extern FILE *yyin;              /* declared by lex */
extern char *yytext;            /* declared by lex */
extern char buf[256];           /* declared in lex.l */	
extern int yylex(void);

%}

%token SEMICOLON    /* ; */
%token COMMA 
%token ID           /* identifier */
%token INT DOUBLE FLOAT STRING BOOL  /* keyword */
%token INT_constant FLOAT_constant SCIENTIFIC_constant STRING_constant 
%token LEFT_parentheses RIGHT_parentheses 
%token LEFT_square_brackets RIGHT_square_brackets
%token LEFT_curly_brackets RIGHT_curly_brackets
%token PLUS MINUS MULTIPLY DIVIDE MODULO
%token LESS LESS_or_EQUAL EQUAL GREATER_or_EQUAL GREATER NOTEQUAL
%token AND OR NOT
%token ASSIGN
%token READ PRINT
%token IF ELSE 
%token WHILE DO FOR 
%token RETURN BREAK CONTINUE
%token TRUE FALSE BOOLEAN
%token VOID CONST

%left OR
%left AND
%nonassoc NOT
%left LESS LESS_or_EQUAL EQUAL GREATER_or_EQUAL GREATER NOTEQUAL
%left PLUS MINUS
%left MULTIPLY DIVIDE MODULO
%nonassoc UMINUS 

%%

program : decl_lists funct_def decl_and_def_lists
	;

decl_and_def_lists : decl_and_def_list | epsilon
					;
	
decl_and_def_list	: decl_and_def_list declaration_list
			| decl_and_def_list funct_def
			| declaration_list
			| funct_def
			;
decl_lists : decl_lists declaration_list | epsilon
			;
			
declaration_list : const_decl
                 | var_decl
                 | funct_decl
				 ;
/*variable declaration*/
var_decl : type identifier_list SEMICOLON
         ;
identifier_list : identifier_list COMMA def_or_nodef | def_or_nodef
				;
def_or_nodef :  nodef_id_or_array | def_id_or_array
			;
def_id_or_array : identifier ASSIGN expression | array ASSIGN LEFT_curly_brackets zero_or_more_expression RIGHT_curly_brackets
			;
zero_or_more_expression : expression_list | epsilon
			;
expression_list : expression_list COMMA expression | expression
				;

/*constant declaration*/		 
const_decl : CONST type const_list SEMICOLON 
			;
const_list : const_list COMMA identifier ASSIGN literal_constant | identifier ASSIGN literal_constant  
				;
literal_constant : INT_constant | FLOAT_constant | SCIENTIFIC_constant | STRING_constant | TRUE | FALSE
				;

/*function declaration*/
funct_decl : type identifier LEFT_parentheses formal_arguments RIGHT_parentheses SEMICOLON | VOID identifier LEFT_parentheses formal_arguments RIGHT_parentheses SEMICOLON
			;
			
formal_arguments : arguments | epsilon 
				;
arguments : arguments COMMA type nodef_id_or_array | type nodef_id_or_array 
			;
nodef_id_or_array : identifier | array 
			;
array : identifier dimension 
		;
dimension : dimension LEFT_square_brackets INT_constant RIGHT_square_brackets | LEFT_square_brackets INT_constant RIGHT_square_brackets
			;
variable_reference : identifier expression_dimension
					;
expression_dimension : expression_dimension LEFT_square_brackets expression RIGHT_square_brackets | LEFT_square_brackets expression RIGHT_square_brackets
					;
				 
/*function definition*/
funct_def : type identifier LEFT_parentheses formal_arguments RIGHT_parentheses compound_statement | VOID identifier LEFT_parentheses formal_arguments RIGHT_parentheses compound_statement
			;

statement : compound_statement 
			| simple_statement 
			| conditional_statement
			| while_statement
			| for_statement
			| jump_statement
			| function_invocation SEMICOLON
			;
			
compound_statement : LEFT_curly_brackets compound_content RIGHT_curly_brackets
					;
compound_content : compound_content var_decl | compound_content const_decl | compound_content statement | epsilon
					;
simple_statement : variable_reference ASSIGN expression SEMICOLON
				| identifier ASSIGN expression SEMICOLON
				| PRINT expression SEMICOLON
				| READ variable_reference SEMICOLON
					;
conditional_statement : IF LEFT_parentheses expression RIGHT_parentheses LEFT_curly_brackets compound_content RIGHT_curly_brackets ELSE_statement
						;
ELSE_statement : ELSE LEFT_curly_brackets compound_content RIGHT_curly_brackets | epsilon
				;
while_statement : WHILE LEFT_parentheses expression RIGHT_parentheses LEFT_curly_brackets compound_content RIGHT_curly_brackets
				| DO LEFT_curly_brackets compound_content RIGHT_curly_brackets WHILE LEFT_parentheses expression RIGHT_parentheses SEMICOLON
				;
for_statement : FOR LEFT_parentheses for_content SEMICOLON for_content SEMICOLON for_content RIGHT_parentheses LEFT_curly_brackets compound_content RIGHT_curly_brackets
				;
for_content : identifier ASSIGN expression | expression | epsilon
			;
jump_statement : RETURN expression SEMICOLON | BREAK SEMICOLON | CONTINUE SEMICOLON
				;
				
expression : expression OR expression
			| expression AND expression
			| NOT expression
			| expression GREATER expression
			| expression GREATER_or_EQUAL expression
			| expression EQUAL expression
			| expression LESS_or_EQUAL expression
			| expression LESS expression
			| expression NOTEQUAL expression
			| expression PLUS expression 
			| expression MINUS expression
			| expression MULTIPLY expression
			| expression DIVIDE expression
			| expression MODULO expression
		    | MINUS expression %prec UMINUS 
			| LEFT_parentheses expression RIGHT_parentheses 
			| literal_constant
			| function_invocation
			| identifier
			| variable_reference
			;

/*no SEMICOLON!!!!*/
function_invocation : identifier LEFT_parentheses zero_or_more_expression RIGHT_parentheses
					;
				
type : INT | DOUBLE | FLOAT | STRING | BOOL 
		; 

identifier : ID 
			;	

epsilon : ;

%%

int yyerror( char *msg )
{
  fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
  fprintf( stderr, "|--------------------------------------------------------------------------\n" );
  exit(-1);
}

int  main( int argc, char **argv )
{
	if( argc != 2 ) {
		fprintf(  stdout,  "Usage:  ./parser  [filename]\n"  );
		exit(0);
	}

	FILE *fp = fopen( argv[1], "r" );
	
	if( fp == NULL )  {
		fprintf( stdout, "Open  file  error\n" );
		exit(-1);
	}
	
	yyin = fp;
	yyparse();

	fprintf( stdout, "\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	fprintf( stdout, "|  There is no syntactic error!  |\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	exit(0);
}