%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "structure.h"

extern int linenum;
extern FILE *yyin;
extern char *yytext;
extern char buf[256];
extern int Opt_Symbol;

int yylex();
int yyerror( char *msg );

symbol_table* tablelisthead;
attribute* attributehead;
char* arraydim;
char* idarraydim;
idlist* idlisthead;
constlist* constlisthead; 


%}

%union	{
	char* str;
}

%token  <str> ID
%token  <str> INT_CONST
%token  <str> FLOAT_CONST
%token  <str> SCIENTIFIC
%token  <str> STR_CONST

%token  LE_OP
%token  NE_OP
%token  GE_OP
%token  EQ_OP
%token  AND_OP
%token  OR_OP

%token  READ
%token  BOOLEAN
%token  WHILE
%token  DO
%token  IF
%token  ELSE
%token  <str> TRUE
%token  <str> FALSE
%token  FOR
%token  <str> INT
%token  PRINT
%token  <str> BOOL
%token  <str> VOID
%token  <str> FLOAT
%token  <str> DOUBLE
%token  <str> STRING
%token  CONTINUE
%token  BREAK
%token  RETURN
%token  CONST

%token  L_PAREN
%token  R_PAREN
%token  COMMA
%token  SEMICOLON
%token  <str> ML_BRACE
%token  <str> MR_BRACE
%token  L_BRACE
%token  R_BRACE
%token  ADD_OP
%token  SUB_OP
%token  MUL_OP
%token  DIV_OP
%token  MOD_OP
%token  ASSIGN_OP
%token  LT_OP
%token  GT_OP
%token  NOT_OP

%type <str> scalar_type
%type <str> array_decl
%type <str> literal_const

/*  Program 
    Function 
    Array 
    Const 
    IF 
    ELSE 
    RETURN 
    FOR 
    WHILE
*/
%start program
%%

program : decl_list funct_def decl_and_def_list {tablelisthead = poptablelist(tablelisthead,Opt_Symbol);}
        ;

decl_list : decl_list var_decl
          | decl_list const_decl
          | decl_list funct_decl
          |
          ;


decl_and_def_list : decl_and_def_list var_decl
                  | decl_and_def_list const_decl
                  | decl_and_def_list funct_decl
                  | decl_and_def_list funct_def
                  | 
                  ;

funct_def : scalar_type ID L_PAREN R_PAREN compound_statement 
			{
				if(searchentrylist(tablelisthead,$2)){
					tablelisthead->entry_list = insertentrylist(tablelisthead,$2,"function",tablelisthead->level,$1,NULL);
				}
			}
          | scalar_type ID L_PAREN parameter_list R_PAREN compound_statement 
		  {
				if(searchentrylist(tablelisthead,$2)){
					tablelisthead->entry_list = insertentrylist(tablelisthead,$2,"function",tablelisthead->level,$1,attributehead);
				}
				attributehead = NULL;
			}
          | VOID ID L_PAREN R_PAREN compound_statement
		  {
				if(searchentrylist(tablelisthead,$2)){
					tablelisthead->entry_list  = insertentrylist(tablelisthead,$2,"function",tablelisthead->level,$1,NULL);
				}
			}
          | VOID ID L_PAREN parameter_list R_PAREN compound_statement
		  {
				if(searchentrylist(tablelisthead,$2)){
					tablelisthead->entry_list  = insertentrylist(tablelisthead,$2,"function",tablelisthead->level,$1,attributehead);
				}
				attributehead = NULL;
			}
          ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON 
			{
				tablelisthead->entry_list  = insertentrylist(tablelisthead,$2,"function",tablelisthead->level,$1,NULL);
			}
           | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON 
			{
				tablelisthead->entry_list  = insertentrylist(tablelisthead,$2,"function",tablelisthead->level,$1,attributehead);
				attributehead = NULL;
			}
           | VOID ID L_PAREN R_PAREN  
		   {
				tablelisthead->entry_list  = insertentrylist(tablelisthead,$2,"function",tablelisthead->level,$1,NULL);
			}
           | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON 
			{
				tablelisthead->entry_list  = insertentrylist(tablelisthead,$2,"function",tablelisthead->level,$1,attributehead);
				attributehead = NULL;
				
			}
           ;

parameter_list : parameter_list COMMA scalar_type ID 
				{	
					if(searchattribute(attributehead,$4)){
						attributehead = insertattribute(attributehead,$3,$4);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$4);
					}
				}
               | parameter_list COMMA scalar_type array_decl
			   {

					char* temp = arraydim; 
					arraydim = (char*)malloc(strlen(temp)+strlen($3)+1);
					strcpy(arraydim,$3);
					strcat(arraydim,temp);
					if(searchattribute(attributehead,$4)){
						attributehead = insertattribute(attributehead,arraydim,$4);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$4);
					}
					free(temp);
			   }
               | scalar_type array_decl 
			   {
					char* temp = arraydim; 
					arraydim = (char*)malloc(strlen(temp)+strlen($1)+1);
					strcpy(arraydim,$1);
					strcat(arraydim,temp);
					if(searchattribute(attributehead,$2)){
						attributehead = insertattribute(attributehead,arraydim,$2);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$2);
					}
					free(temp);
				}
               | scalar_type ID 
			   {
					if(searchattribute(attributehead,$2)){
						attributehead = insertattribute(attributehead,$1,$2);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$2);
					}
				}
               ;

var_decl : scalar_type identifier_list SEMICOLON 
			{	
				idlist* current = idlisthead;
				idlist* temp;

				while(current != NULL){
					temp = current;
					if(current->arraytype == NULL){
						if(searchentrylist(tablelisthead,current->id)){
							tablelisthead->entry_list  = insertentrylist(tablelisthead,current->id,"variable",tablelisthead->level,$1,NULL);
						}
						else{
							printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,current->id);
						}
					}
					else{ 
						if(searchentrylist(tablelisthead,current->id)){
							idarraydim = (char*)malloc(strlen(current->arraytype)+strlen($1)+1);
							strcpy(idarraydim,$1);
							strcat(idarraydim,current->arraytype);
							tablelisthead->entry_list  = insertentrylist(tablelisthead,current->id,"variable",tablelisthead->level,idarraydim,NULL);
							free(idarraydim);
						}
						else{
							printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,current->id);
						}
					}
					current = current->next;
					free(temp);
				}
				idlisthead = NULL;
			}
         ;

identifier_list : identifier_list COMMA ID 
				{	
					if(searchidlist(idlisthead,$3)){
						idlisthead = insertidlist(idlisthead,$3,NULL);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$3);
					}
				}
                | identifier_list COMMA ID ASSIGN_OP logical_expression 
				{	
					if(searchidlist(idlisthead,$3)){
						idlisthead = insertidlist(idlisthead,$3,NULL);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$3);
					}
				}
                | identifier_list COMMA array_decl ASSIGN_OP initial_array 
				{
					char* temp = arraydim; 
					if(searchidlist(idlisthead,$3)){
						idlisthead = insertidlist(idlisthead,$3,arraydim);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$3);
					}
					arraydim = NULL;
					free(temp);
				}
                | identifier_list COMMA array_decl 
				{	
					char* temp = arraydim; 
					if(searchidlist(idlisthead,$3)){
						idlisthead = insertidlist(idlisthead,$3,arraydim);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$3);
					}
					arraydim = NULL;
					free(temp);
				}
                | array_decl ASSIGN_OP initial_array 
				{
					char* temp = arraydim; 
					if(searchidlist(idlisthead,$1)){
						idlisthead = insertidlist(idlisthead,$1,arraydim);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$1);
					}
					arraydim = NULL;
					free(temp);
				}
                | array_decl 
				{
					char* temp = arraydim; 
					if(searchidlist(idlisthead,$1)){
						idlisthead = insertidlist(idlisthead,$1,arraydim);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$1);
					}
					arraydim = NULL;
					free(temp);
				}
                | ID ASSIGN_OP logical_expression 
				{
					if(searchidlist(idlisthead,$1)){
						idlisthead = insertidlist(idlisthead,$1,NULL);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$1);
					}
				}
                | ID 
				{
					if(searchidlist(idlisthead,$1)){
						idlisthead = insertidlist(idlisthead,$1,NULL);
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$1);
					}
				}
                ;

initial_array : L_BRACE literal_list R_BRACE
              ;

literal_list : literal_list COMMA logical_expression
             | logical_expression
             | 
             ;

const_decl : CONST scalar_type const_list SEMICOLON 
			{
				constlist* current = constlisthead;
				while(current != NULL){
					if(searchentrylist(tablelisthead,current->id)){
						attribute* tmp = (attribute*)malloc(sizeof(attribute));
						//printf("temp attribute malloc finish\n");
						tmp->id = (char*)malloc(strlen(current->id)+1);
						//printf("temp->id malloc finish\n");
						strcpy(tmp->id,current->id);
						//printf("strcpy tmp->id finish\n");
						tmp->typeorvalue = (char*)malloc(strlen(current->value)+1);
						tmp->next = NULL;
						//printf("temp->typeorvalue malloc finish\n");
						//printf("%s\n",current->value);
						strcpy(tmp->typeorvalue,current->value);
						//printf("strcpy tmp->typeorvalue finish\n");
						//printf("%s\n",tmp->typeorvalue);
						tablelisthead->entry_list = insertentrylist(tablelisthead,current->id,"constant",tablelisthead->level,$2,tmp);
						
					}
					else{
						printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,current->id);
					}
					current = current->next;
				}
				constlisthead = NULL;
			}
			;
const_list : const_list COMMA ID ASSIGN_OP literal_const 
			{
				if(searchconstlist(constlisthead,$3)){
					constlisthead = insertconstlist(constlisthead,$3,$5);
					//printf("insertconstlist id= % s,value = %s\n",$3,$5);
				}
				else{
					printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$3);
				}
				
			}
           | ID ASSIGN_OP literal_const 
		   {	
				if(searchconstlist(constlisthead,$1)){
					constlisthead = insertconstlist(constlisthead,$1,$3);
					//printf("insertconstlist id= % s,value = %s\n",$1,$3);
				}
				else{
					printf("##########Error at Line #%d: %s redeclared.##########\n",linenum,$1);
				}
				
			}
           ;

array_decl : ID dim {$$ = $1;}
           ;

dim : dim ML_BRACE INT_CONST MR_BRACE 
	{
		char* temp = arraydim; 
		arraydim = (char*)malloc(strlen(temp)+strlen($2)+strlen($3)+strlen($4)+1);
		strcpy(arraydim,temp);
		strcat(arraydim,$2);
		strcat(arraydim,$3);
		strcat(arraydim,$4);
		free(temp);
	}
    | ML_BRACE INT_CONST MR_BRACE 
	{
		char* temp = arraydim; 
		arraydim = (char*)malloc(strlen($1)+strlen($2)+strlen($3)+1);
		strcpy(arraydim,$1);
		strcat(arraydim,$2);
		strcat(arraydim,$3);
		if(temp != NULL){
			free(temp);
		}
		
	}
    ;

compound_statement : L_BRACE 
					{	
						tablelisthead = inserttablelist(tablelisthead);
						if(attributehead != NULL){
							attribute* current = attributehead;
							while(current != NULL){
								tablelisthead->entry_list  = insertentrylist(tablelisthead,current->id,"parameter",tablelisthead->level,current->typeorvalue,NULL);
								current = current->next;
							}
						}	
					} 
					var_const_stmt_list R_BRACE
					{	
						tablelisthead = poptablelist(tablelisthead,Opt_Symbol);
					}
                   ;

var_const_stmt_list : var_const_stmt_list statement 
                    | var_const_stmt_list var_decl
                    | var_const_stmt_list const_decl
                    |
                    ;

statement : compound_statement
          | simple_statement
          | conditional_statement
          | while_statement
          | for_statement
          | function_invoke_statement
          | jump_statement
          ;     

simple_statement : variable_reference ASSIGN_OP logical_expression SEMICOLON
                 | PRINT logical_expression SEMICOLON
                 | READ variable_reference SEMICOLON
                 ;

conditional_statement : IF L_PAREN logical_expression R_PAREN compound_statement
                      | IF L_PAREN logical_expression R_PAREN 
                            compound_statement
                        ELSE
                            compound_statement
                      ;
while_statement : WHILE L_PAREN logical_expression R_PAREN
                    compound_statement
                | DO compound_statement WHILE L_PAREN logical_expression R_PAREN SEMICOLON
                ;

for_statement : FOR L_PAREN initial_expression_list SEMICOLON control_expression_list SEMICOLON increment_expression_list R_PAREN 
                    compound_statement
              ;

initial_expression_list : initial_expression
                        |
                        ;

initial_expression : initial_expression COMMA variable_reference ASSIGN_OP logical_expression
                   | initial_expression COMMA logical_expression
                   | logical_expression
                   | variable_reference ASSIGN_OP logical_expression

control_expression_list : control_expression
                        |
                        ;

control_expression : control_expression COMMA variable_reference ASSIGN_OP logical_expression
                   | control_expression COMMA logical_expression
                   | logical_expression
                   | variable_reference ASSIGN_OP logical_expression
                   ;

increment_expression_list : increment_expression 
                          |
                          ;

increment_expression : increment_expression COMMA variable_reference ASSIGN_OP logical_expression
                     | increment_expression COMMA logical_expression
                     | logical_expression
                     | variable_reference ASSIGN_OP logical_expression
                     ;

function_invoke_statement : ID L_PAREN logical_expression_list R_PAREN SEMICOLON
                          | ID L_PAREN R_PAREN SEMICOLON
                          ;

jump_statement : CONTINUE SEMICOLON
               | BREAK SEMICOLON
               | RETURN logical_expression SEMICOLON
               ;

variable_reference : array_list
                   | ID
                   ;


logical_expression : logical_expression OR_OP logical_term
                   | logical_term
                   ;

logical_term : logical_term AND_OP logical_factor
             | logical_factor
             ;

logical_factor : NOT_OP logical_factor
               | relation_expression
               ;

relation_expression : relation_expression relation_operator arithmetic_expression
                    | arithmetic_expression
                    ;

relation_operator : LT_OP
                  | LE_OP
                  | EQ_OP
                  | GE_OP
                  | GT_OP
                  | NE_OP
                  ;

arithmetic_expression : arithmetic_expression ADD_OP term
                      | arithmetic_expression SUB_OP term
                      | term
                      ;

term : term MUL_OP factor
     | term DIV_OP factor
     | term MOD_OP factor
     | factor
     ;

factor : SUB_OP factor
       | literal_const
       | variable_reference
       | L_PAREN logical_expression R_PAREN
       | ID L_PAREN logical_expression_list R_PAREN
       | ID L_PAREN R_PAREN
       ;

logical_expression_list : logical_expression_list COMMA logical_expression
                        | logical_expression
                        ;

array_list : ID dimension
           ;

dimension : dimension ML_BRACE logical_expression MR_BRACE         
          | ML_BRACE logical_expression MR_BRACE
          ;



scalar_type : INT {$$ = $1;}
            | DOUBLE {$$ = $1;}
            | STRING {$$ = $1;}
            | BOOL {$$ = $1;}
            | FLOAT {$$ = $1;}
            ;
 
literal_const : INT_CONST {$$ = $1;}
              | FLOAT_CONST {$$ = $1;}
              | SCIENTIFIC {$$ = $1;}
              | STR_CONST {$$ = $1;}
              | TRUE {$$ = $1;}
              | FALSE {$$ = $1;}
              ;


%%

int yyerror( char *msg )
{
    fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
    fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
    fprintf( stderr, "|\n" );
    fprintf( stderr, "| Unmatched token: %s\n", yytext );
    fprintf( stderr, "|--------------------------------------------------------------------------\n" );
    exit(-1);
    //  fprintf( stderr, "%s\t%d\t%s\t%s\n", "Error found in Line ", linenum, "next token: ", yytext );
}



