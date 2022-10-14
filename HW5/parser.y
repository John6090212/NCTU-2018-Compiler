%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "header.h"
#include "symtab.h"
#include "semcheck.h"

extern int linenum;
extern FILE	*yyin;
extern char	*yytext;
extern char buf[256];
extern int Opt_Symbol;		/* declared in lex.l */
int yylex();
int scope = 0;
char fileName[256];
char frontfileName[256];
struct SymTable *symbolTable;
__BOOLEAN paramError;
struct PType *funcReturn;
__BOOLEAN semError = __FALSE;
int inloop = 0;
int local_count = 0;
int temp_local_count;
int function_flag = 0;
FILE *writefile;
int label_count = 0;
SEMTYPE var_decl_type;
int elselabel_count = 0;
int whilelabel_count = 0;
int forlabel_count = 0;
int control_counter = 0;
int temp_register = 98;
int tempcount;
SEMTYPE first_operand;
__BOOLEAN mainflag = __FALSE;
__BOOLEAN mainreturnflag = __FALSE;

typedef struct stack{
    int elselabel_count;
    struct stack *next;
}ifstack_t;
ifstack_t *ifhead = NULL;

int if_isEmpty(){
    if (ifhead == NULL)
        return 1;
    return 0;
}

void if_push(int num){
    ifstack_t *new_node=(ifstack_t *)malloc(sizeof(ifstack_t));
    new_node->elselabel_count=num;
    new_node->next=NULL;

    if (if_isEmpty() == 1)
        ifhead=new_node;
    else{
        new_node->next=ifhead;
        ifhead=new_node;
    }
}

int if_pop(){
    if (if_isEmpty() == 1){
		printf("ifstack is empty!\n");
	}
    else{
        ifstack_t *temp= ifhead;
        ifhead=ifhead->next;
        return temp->elselabel_count;
    }
}

typedef struct whilestack{
    int whilelabel_count;
    struct whilestack *next;
}whilestack_t;
whilestack_t *whilehead = NULL;

int while_isEmpty(){
    if (whilehead == NULL)
        return 1;
    return 0;
}

void while_push(int num){
    whilestack_t *new_node=(whilestack_t *)malloc(sizeof(whilestack_t));
    new_node->whilelabel_count=num;
    new_node->next=NULL;

    if (while_isEmpty() == 1)
        whilehead=new_node;
    else{
        new_node->next=whilehead;
        whilehead=new_node;
    }
}

int while_pop(){
    if (while_isEmpty() == 1){
		printf("whilestack is empty!\n");
	}
    else{
        whilestack_t *temp= whilehead;
        whilehead=whilehead->next;
        return temp->whilelabel_count;
    }
}

typedef struct forstack{
    int forlabel_count;
    struct forstack *next;
}forstack_t;
forstack_t *forhead = NULL;

int for_isEmpty(){
    if (forhead == NULL)
        return 1;
    return 0;
}

void for_push(int num){
    forstack_t *new_node=(forstack_t *)malloc(sizeof(forstack_t));
    new_node->forlabel_count=num;
    new_node->next=NULL;

    if (for_isEmpty() == 1)
        forhead=new_node;
    else{
        new_node->next=forhead;
        forhead=new_node;
    }
}

int for_pop(){
    if (for_isEmpty() == 1){
		printf("forstack is empty!\n");
	}
    else{
        forstack_t *temp= forhead;
        forhead=forhead->next;
        return temp->forlabel_count;
    }
}

%}

%union {
	int intVal;
	float floatVal;	
	char *lexeme;
	struct idNode_sem *id;
	struct ConstAttr *constVal;
	struct PType *ptype;
	struct param_sem *par;
	struct expr_sem *exprs;
	struct expr_sem_node *exprNode;
	struct constParam *constNode;
	struct varDeclParam* varDeclNode;
};

%token	LE_OP NE_OP GE_OP EQ_OP AND_OP OR_OP
%token	READ BOOLEAN WHILE DO IF ELSE TRUE FALSE FOR INT PRINT BOOL VOID FLOAT DOUBLE STRING CONTINUE BREAK RETURN CONST
%token	L_PAREN R_PAREN COMMA SEMICOLON ML_BRACE MR_BRACE L_BRACE R_BRACE ADD_OP SUB_OP MUL_OP DIV_OP MOD_OP ASSIGN_OP LT_OP GT_OP NOT_OP

%token <lexeme>ID
%token <intVal>INT_CONST 
%token <floatVal>FLOAT_CONST
%token <floatVal>SCIENTIFIC
%token <lexeme>STR_CONST

%type<ptype> scalar_type dim
%type<par> array_decl parameter_list
%type<constVal> literal_const
%type<constNode> const_list 
%type<exprs> variable_reference logical_expression logical_term logical_factor relation_expression arithmetic_expression term factor logical_expression_list literal_list initial_array
%type<intVal> relation_operator add_op mul_op dimension
%type<varDeclNode> identifier_list


%start program
%%

program :		{
					char temp;
					int i;
					frontfileName[0] = 'o';
					frontfileName[1] = 'u';
					frontfileName[2] = 't';
					frontfileName[3] = 'p';
					frontfileName[4] = 'u';
					frontfileName[5] = 't';
					frontfileName[6] = '\0';
					writefile = fopen("output.j","w");
					fprintf(writefile,".class public %s\n",frontfileName);
					fprintf(writefile,".super java/lang/Object\n");
					fprintf(writefile,".field public static _sc Ljava/util/Scanner;\n");
				}
				decl_list 
			    funct_def
				decl_and_def_list 
				{
					checkUndefinedFunc(symbolTable);
					if(Opt_Symbol == 1)
					printSymTable( symbolTable, scope );	
					fclose(writefile);
				}
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

		  
funct_def : scalar_type ID L_PAREN R_PAREN 
			{
				funcReturn = $1; 
				struct SymNode *node;
				node = findFuncDeclaration( symbolTable, $2 );
				if(strcmp($2,"main") == 0){
					mainflag = __TRUE;
					local_count = 1;
					fprintf(writefile,".method public static main([Ljava/lang/String;)V\n");
					fprintf(writefile,".limit stack 100\n");
					fprintf(writefile,".limit locals 100\n");
					fprintf(writefile,"new java/util/Scanner\n");
					fprintf(writefile,"dup\n");
					fprintf(writefile,"getstatic java/lang/System/in Ljava/io/InputStream;\n");
					fprintf(writefile,"invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\n");
					fprintf(writefile,"putstatic %s/_sc Ljava/util/Scanner;\n",frontfileName);
				}
				else{
					tempcount = local_count;
					local_count = 0;
					if($1->type == INTEGER_t){
						fprintf(writefile,".method public static %s()I\n",$2);
						fprintf(writefile,".limit stack 100\n");
						fprintf(writefile,".limit locals 100\n");
					}
					else if($1->type == FLOAT_t){
						fprintf(writefile,".method public static %s()F\n",$2);
						fprintf(writefile,".limit stack 100\n");
						fprintf(writefile,".limit locals 100\n");
					}
					else if($1->type == DOUBLE_t){
						fprintf(writefile,".method public static %s()D\n",$2);
						fprintf(writefile,".limit stack 100\n");
						fprintf(writefile,".limit locals 100\n");
					}
					else if($1->type == BOOLEAN_t){
						fprintf(writefile,".method public static %s()Z\n",$2);
						fprintf(writefile,".limit stack 100\n");
						fprintf(writefile,".limit locals 100\n");
					}
				}
				if( node != 0 ){
					verifyFuncDeclaration( symbolTable, 0, $1, node );
				}
				else{
					insertFuncIntoSymTable( symbolTable, $2, 0, $1, scope, __TRUE );
				}
			}
			compound_statement 
			{ 
				funcReturn = 0;
				if(mainflag == __TRUE && mainreturnflag == __FALSE){
					fprintf(writefile,"return\n");
				}
				if(strcmp($2,"main") != 0){
					local_count = tempcount;
				}
				mainflag = __FALSE;
				mainreturnflag = __FALSE;
				fprintf(writefile,".end method\n");
			}	
		  | scalar_type ID L_PAREN parameter_list R_PAREN  
			{				
				funcReturn = $1;
				
				paramError = checkFuncParam( $4 );
				
				fprintf(writefile,".method public static %s(",$2);
				struct param_sem *temp = $4;
				while(temp != NULL){
					if(temp->pType->type == INTEGER_t){
						fprintf(writefile,"I");
					}
					else if(temp->pType->type == FLOAT_t){
						fprintf(writefile,"F");
					}
					else if(temp->pType->type == DOUBLE_t){
						fprintf(writefile,"D");
					}
					else if(temp->pType->type == BOOLEAN_t){
						fprintf(writefile,"Z");
					}
					temp = temp->next;
				}
				if($1->type == INTEGER_t){
					fprintf(writefile,")I\n");
				}
				else if($1->type == FLOAT_t){
					fprintf(writefile,")F\n");
				}
				else if($1->type == DOUBLE_t){
					fprintf(writefile,")D\n");
				}
				else if($1->type == BOOLEAN_t){
					fprintf(writefile,")Z\n");
				}
				tempcount = local_count;
				local_count = 0;
				fprintf(writefile,".limit stack 100\n");
				fprintf(writefile,".limit locals 100\n");
				
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;
				}
				// check and insert function into symbol table
				else{
					struct SymNode *node;
					node = findFuncDeclaration( symbolTable, $2 );
					if( node != 0 ){
						if(verifyFuncDeclaration( symbolTable, $4, $1, node ) == __TRUE){
							temp_local_count = local_count;
							function_flag = 1;
							local_count = insertParamIntoSymTable( symbolTable, $4, scope+1, local_count);
						}				
					}
					else{
						temp_local_count = local_count;
						function_flag = 1;
						local_count = insertParamIntoSymTable( symbolTable, $4, scope+1, local_count);				
						insertFuncIntoSymTable( symbolTable, $2, $4, $1, scope, __TRUE );
					}
				}
				
				
				
			} 	
			compound_statement 
			{ 
				funcReturn = 0; 
				local_count = tempcount;
				fprintf(writefile,".end method\n");
			}
		  | VOID ID L_PAREN R_PAREN 
			{
				funcReturn = createPType(VOID_t); 
				struct SymNode *node;
				node = findFuncDeclaration( symbolTable, $2 );
				if(strcmp($2,"main") == 0){
					mainflag = __TRUE;
					local_count = 1;
					fprintf(writefile,".method public static main([Ljava/lang/String;)V\n");
					fprintf(writefile,".limit stack 100\n");
					fprintf(writefile,".limit locals 100\n");
					fprintf(writefile,"new java/util/Scanner\n");
					fprintf(writefile,"dup\n");
					fprintf(writefile,"getstatic java/lang/System/in Ljava/io/InputStream;\n");
					fprintf(writefile,"invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\n");
					fprintf(writefile,"putstatic %s/_sc Ljava/util/Scanner;\n",frontfileName);
				}
				else{
					tempcount = local_count;
					fprintf(writefile,".method public static %s()V\n",$2);
					fprintf(writefile,".limit stack 100\n");
					fprintf(writefile,".limit locals 100\n");
				}
				if( node != 0 ){
					verifyFuncDeclaration( symbolTable, 0, createPType( VOID_t ), node );					
				}
				else{
					insertFuncIntoSymTable( symbolTable, $2, 0, createPType( VOID_t ), scope, __TRUE );	
				}
			}
			compound_statement 
			{ 
				funcReturn = 0; 
				mainflag = __FALSE;
				if(strcmp($2,"main") != 0){
					local_count = tempcount;
				}
				fprintf(writefile,"return\n");
				fprintf(writefile,".end method\n");
			}	
		  | VOID ID L_PAREN parameter_list R_PAREN
			{									
				funcReturn = createPType(VOID_t);
				
				paramError = checkFuncParam( $4 );
				
				fprintf(writefile,".method public static %s(",$2);
				struct param_sem *temp = $4;
				while(temp != NULL){
					if(temp->pType->type == INTEGER_t){
						fprintf(writefile,"I");
					}
					else if(temp->pType->type == FLOAT_t){
						fprintf(writefile,"F");
					}
					else if(temp->pType->type == DOUBLE_t){
						fprintf(writefile,"D");
					}
					else if(temp->pType->type == BOOLEAN_t){
						fprintf(writefile,"Z");
					}
					temp = temp->next;
				}
				fprintf(writefile,")V\n");
				tempcount = local_count;
				local_count = 0;
				fprintf(writefile,".limit stack 100\n");
				fprintf(writefile,".limit locals 100\n");
				
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;
				}
				// check and insert function into symbol table
				else{
					struct SymNode *node;
					node = findFuncDeclaration( symbolTable, $2 );

					if( node != 0 ){
						if(verifyFuncDeclaration( symbolTable, $4, createPType( VOID_t ), node ) == __TRUE){	
							temp_local_count = local_count;
							function_flag = 1;
							local_count = insertParamIntoSymTable( symbolTable, $4, scope+1, local_count);				
						}
					}
					else{
						temp_local_count = local_count;
						function_flag = 1;
						local_count = insertParamIntoSymTable( symbolTable, $4, scope+1, local_count);				
						insertFuncIntoSymTable( symbolTable, $2, $4, createPType( VOID_t ), scope, __TRUE );
					}
				}
			} 
			compound_statement 
			{ 
				funcReturn = 0; 
				local_count = tempcount;
				fprintf(writefile,"return\n");
				fprintf(writefile,".end method\n");
			}		  
		  ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON
			{
				insertFuncIntoSymTable( symbolTable, $2, 0, $1, scope, __FALSE );	
			}
		   | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON
		    {
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;
				}
				else {
					insertFuncIntoSymTable( symbolTable, $2, $4, $1, scope, __FALSE );
				}
			}
		   | VOID ID L_PAREN R_PAREN SEMICOLON
			{				
				insertFuncIntoSymTable( symbolTable, $2, 0, createPType( VOID_t ), scope, __FALSE );
			}
		   | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON
			{
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;	
				}
				else {
					insertFuncIntoSymTable( symbolTable, $2, $4, createPType( VOID_t ), scope, __FALSE );
				}
			}
		   ;

parameter_list : parameter_list COMMA scalar_type ID
			   {
				struct param_sem *ptr;
				ptr = createParam( createIdList( $4 ), $3 );
				param_sem_addParam( $1, ptr );
				$$ = $1;
			   }
			   | parameter_list COMMA scalar_type array_decl
			   {
				$4->pType->type= $3->type;
				param_sem_addParam( $1, $4 );
				$$ = $1;
			   }
			   | scalar_type array_decl 
			   { 
				$2->pType->type = $1->type;  
				$$ = $2;
			   }
			   | scalar_type ID { $$ = createParam( createIdList( $2 ), $1 ); }
			   ;

var_decl : scalar_type identifier_list SEMICOLON
			{
				struct varDeclParam *ptr;
				struct SymNode *newNode;
				for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {						
					if( verifyRedeclaration( symbolTable, ptr->para->idlist->value, scope ) == __FALSE ) { }
					else {
						if( verifyVarInitValue( $1, ptr, symbolTable, scope ) ==  __TRUE ){	
							if(scope == 0){
								newNode = createVarNode( ptr->para->idlist->value, scope, ptr->para->pType,-1);
							}
							else{
								newNode = createVarNode( ptr->para->idlist->value, scope, ptr->para->pType,ptr->local_number);
							}
							insertTab( symbolTable, newNode );		
							
						}
					}
				}
			}
			;

identifier_list : identifier_list COMMA ID
				{					
					struct param_sem *ptr;	
					struct varDeclParam *vptr;				
					ptr = createParam( createIdList( $3 ), createPType( VOID_t ) );
					vptr = createVarDeclParam( ptr, 0 );
					if(scope == 0){
						vptr->local_number = -1;
						if(var_decl_type == INTEGER_t){
							fprintf(writefile,".field public static %s I\n",$3);
						}
						else if(var_decl_type == FLOAT_t){
							fprintf(writefile,".field public static %s F\n",$3);
						}
						else if(var_decl_type == DOUBLE_t){
							fprintf(writefile,".field public static %s D\n",$3);
						}
						else if(var_decl_type == BOOLEAN_t){
							fprintf(writefile,".field public static %s Z\n",$3);
						}
					}
					else{
						vptr->local_number = local_count;
						if(var_decl_type == DOUBLE_t){
							local_count += 2;
						}
						else{
							local_count++;
						}
					}
					
					addVarDeclParam( $1, vptr );
					$$ = $1; 					
				}
                | identifier_list COMMA ID ASSIGN_OP logical_expression
				{
					struct param_sem *ptr;	
					struct varDeclParam *vptr;				
					ptr = createParam( createIdList( $3 ), createPType( VOID_t ) );
					vptr = createVarDeclParam( ptr, $5 );
					vptr->isArray = __TRUE;
					vptr->isInit = __TRUE;	
					if($5->isload == __FALSE){
						if($5->node == NULL){
							if($5->constvalue->category == INTEGER_t){
								fprintf(writefile,"ldc %d\n",$5->constvalue->value.integerVal);
							}
							else if ($5->constvalue->category == FLOAT_t){
								fprintf(writefile,"ldc %f\n",$5->constvalue->value.floatVal);
							}
							else if ($5->constvalue->category == DOUBLE_t){
								fprintf(writefile,"ldc2_w %lf\n",$5->constvalue->value.doubleVal);
							}
							else if ($5->constvalue->category == BOOLEAN_t){
								if($5->constvalue->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($5->node->category == CONSTANT_t){
							if($5->pType->type == INTEGER_t){
								fprintf(writefile,"ldc %d\n",$5->node->attribute->constVal->value.integerVal);
							}
							else if($5->pType->type == FLOAT_t){
								fprintf(writefile,"ldc %f\n",$5->node->attribute->constVal->value.floatVal);
							}
							else if($5->pType->type == DOUBLE_t){
								fprintf(writefile,"ldc2_w %lf\n",$5->node->attribute->constVal->value.doubleVal);
							}
							else if($5->pType->type == BOOLEAN_t){
								if($5->node->attribute->constVal->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($5->node->scope == 0){
							if($5->node->category == FUNCTION_t){
							}
							else if($5->pType->type == INTEGER_t){
								fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$5->node->name);
							}
							else if($5->pType->type == FLOAT_t){
								fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$5->node->name);
							}
							else if($5->pType->type == DOUBLE_t){
								fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$5->node->name);
							}
							else if($5->pType->type == BOOLEAN_t){
								fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$5->node->name);
							}
						}
						else{
							if($5->pType->type == INTEGER_t){
								fprintf(writefile,"iload %d\n",$5->node->local_number);
							}
							else if($5->pType->type == FLOAT_t){
								fprintf(writefile,"fload %d\n",$5->node->local_number);
							}
							else if($5->pType->type == DOUBLE_t){
								fprintf(writefile,"dload %d\n",$5->node->local_number);
							}
							else if($5->pType->type == BOOLEAN_t){
								fprintf(writefile,"iload %d\n",$5->node->local_number);
							}
						}
						$5->isload = __TRUE;
					}
					
					
					
					if(scope == 0){
						vptr->local_number = -1;
						if(var_decl_type == INTEGER_t){
							fprintf(writefile,".field public static %s I\n",$3);
							fprintf(writefile,"putstatic %s/%s I\n",frontfileName,$3);
						}
						else if(var_decl_type == FLOAT_t){
							fprintf(writefile,".field public static %s F\n",$3);
							if($5->pType->type == INTEGER_t){
								fprintf(writefile,"i2f\n");
							}
							fprintf(writefile,"putstatic %s/%s F\n",frontfileName,$3);
						}
						else if(var_decl_type == DOUBLE_t){
							fprintf(writefile,".field public static %s D\n",$3);
							if($5->pType->type == INTEGER_t){
								fprintf(writefile,"i2d\n");
							}
							else if($5->pType->type == FLOAT_t){
								fprintf(writefile,"f2d\n");
							}
							fprintf(writefile,"putstatic %s/%s D\n",frontfileName,$3);
						}
						else if(var_decl_type == BOOLEAN_t){
							fprintf(writefile,".field public static %s Z\n",$3);
							fprintf(writefile,"putstatic %s/%s Z\n",frontfileName,$3);
						}
					}
					else{
						vptr->local_number = local_count;
						
						if(var_decl_type == INTEGER_t || var_decl_type == BOOLEAN_t){
							fprintf(writefile,"istore %d\n",vptr->local_number);
						}
						else if(var_decl_type == FLOAT_t){
							if($5->pType->type == INTEGER_t){
								fprintf(writefile,"i2f\n");
							}
							fprintf(writefile,"fstore %d\n",vptr->local_number);
						}
						else if(var_decl_type == DOUBLE_t){
							if($5->pType->type == INTEGER_t){
								fprintf(writefile,"i2d\n");
							}
							else if($5->pType->type == FLOAT_t){
								fprintf(writefile,"f2d\n");
							}
							fprintf(writefile,"dstore %d\n",vptr->local_number);
						}
						
						if(var_decl_type == DOUBLE_t){
							local_count += 2;
						}
						else{
							local_count++;
						}
					}
					
					addVarDeclParam( $1, vptr );	
					$$ = $1;
					
				}
                | identifier_list COMMA array_decl ASSIGN_OP initial_array
				{
					struct varDeclParam *ptr;
					ptr = createVarDeclParam( $3, $5 );
					ptr->isArray = __TRUE;
					ptr->isInit = __TRUE;
					addVarDeclParam( $1, ptr );
					$$ = $1;	
				}
                | identifier_list COMMA array_decl
				{
					struct varDeclParam *ptr;
					ptr = createVarDeclParam( $3, 0 );
					ptr->isArray = __TRUE;
					addVarDeclParam( $1, ptr );
					$$ = $1;
				}
                | array_decl ASSIGN_OP initial_array
				{	
					$$ = createVarDeclParam( $1 , $3 );
					$$->isArray = __TRUE;
					$$->isInit = __TRUE;	
				}
                | array_decl 
				{ 
					$$ = createVarDeclParam( $1 , 0 ); 
					$$->isArray = __TRUE;
				}
                | ID ASSIGN_OP logical_expression
				{
					struct param_sem *ptr;					
					ptr = createParam( createIdList( $1 ), createPType( VOID_t ) );
					$$ = createVarDeclParam( ptr, $3 );		
					$$->isInit = __TRUE;
					if($3->isload == __FALSE){
						if($3->node == NULL){
							if($3->constvalue->category == INTEGER_t){
								fprintf(writefile,"ldc %d\n",$3->constvalue->value.integerVal);
							}
							else if ($3->constvalue->category == FLOAT_t){
								fprintf(writefile,"ldc %f\n",$3->constvalue->value.floatVal);
							}
							else if ($3->constvalue->category == DOUBLE_t){
								fprintf(writefile,"ldc2_w %lf\n",$3->constvalue->value.doubleVal);
							}
							else if ($3->constvalue->category == BOOLEAN_t){
								if($3->constvalue->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($3->node->category == CONSTANT_t){
							if($3->pType->type == INTEGER_t){
								fprintf(writefile,"ldc %d\n",$3->node->attribute->constVal->value.integerVal);
							}
							else if($3->pType->type == FLOAT_t){
								fprintf(writefile,"ldc %f\n",$3->node->attribute->constVal->value.floatVal);
							}
							else if($3->pType->type == DOUBLE_t){
								fprintf(writefile,"ldc2_w %lf\n",$3->node->attribute->constVal->value.doubleVal);
							}
							else if($3->pType->type == BOOLEAN_t){
								if($3->node->attribute->constVal->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($3->node->scope == 0){
							if($3->node->category == FUNCTION_t){
							}
							else if($3->pType->type == INTEGER_t){
								fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$3->node->name);
							}
							else if($3->pType->type == FLOAT_t){
								fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$3->node->name);
							}
							else if($3->pType->type == DOUBLE_t){
								fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$3->node->name);
							}
							else if($3->pType->type == BOOLEAN_t){
								fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$3->node->name);
							}
						}
						else{
							if($3->pType->type == INTEGER_t){
								fprintf(writefile,"iload %d\n",$3->node->local_number);
							}
							else if($3->pType->type == FLOAT_t){
								fprintf(writefile,"fload %d\n",$3->node->local_number);
							}
							else if($3->pType->type == DOUBLE_t){
								fprintf(writefile,"dload %d\n",$3->node->local_number);
							}
							else if($3->pType->type == BOOLEAN_t){
								fprintf(writefile,"iload %d\n",$3->node->local_number);
							}
						}
						$3->isload = __TRUE;
					}
					
					if(scope == 0){
						$$->local_number = -1;
						if(var_decl_type == INTEGER_t){
							fprintf(writefile,".field public static %s I\n",$1);
							fprintf(writefile,"putstatic %s/%s I\n",frontfileName,$1);
						}
						else if(var_decl_type == FLOAT_t){
							fprintf(writefile,".field public static %s F\n",$1);
							if(var_decl_type == FLOAT_t && $3->pType->type == INTEGER_t){
								fprintf(writefile,"i2f\n");
							}
							fprintf(writefile,"putstatic %s/%s F\n",frontfileName,$1);
						}
						else if(var_decl_type == DOUBLE_t){
							fprintf(writefile,".field public static %s D\n",$1);
							if(var_decl_type == DOUBLE_t && $3->pType->type == INTEGER_t){
								fprintf(writefile,"i2d\n");
							}
							else if(var_decl_type == DOUBLE_t && $3->pType->type == FLOAT_t){
								fprintf(writefile,"f2d\n");
							}
							fprintf(writefile,"putstatic %s/%s D\n",frontfileName,$1);
						}
						else if(var_decl_type == BOOLEAN_t){
							fprintf(writefile,".field public static %s Z\n",$1);
							fprintf(writefile,"putstatic %s/%s Z\n",frontfileName,$1);
						}
					}
					else{
						$$->local_number = local_count;
						if(var_decl_type == INTEGER_t || var_decl_type == BOOLEAN_t){
							fprintf(writefile,"istore %d\n",$$->local_number);
						}
						else if(var_decl_type == FLOAT_t){
							if(var_decl_type == FLOAT_t && $3->pType->type == INTEGER_t){
								fprintf(writefile,"i2f\n");
							}
							fprintf(writefile,"fstore %d\n",$$->local_number);
						}
						else if(var_decl_type == DOUBLE_t){
							if(var_decl_type == DOUBLE_t && $3->pType->type == INTEGER_t){
								fprintf(writefile,"i2d\n");
							}
							else if(var_decl_type == DOUBLE_t && $3->pType->type == FLOAT_t){
								fprintf(writefile,"f2d\n");
							}
							fprintf(writefile,"dstore %d\n",$$->local_number);
						}
						if(var_decl_type == DOUBLE_t){
							local_count += 2;
						}
						else{
							local_count++;
						}
					}
				}
                | ID 
				{
					struct param_sem *ptr;					
					ptr = createParam( createIdList( $1 ), createPType( VOID_t ) );
					$$ = createVarDeclParam( ptr, 0 );
					if(scope == 0){
						$$->local_number = -1;
						if(var_decl_type == INTEGER_t){
							fprintf(writefile,".field public static %s I\n",$1);
						}
						else if(var_decl_type == FLOAT_t){
							fprintf(writefile,".field public static %s F\n",$1);
						}
						else if(var_decl_type == DOUBLE_t){
							fprintf(writefile,".field public static %s D\n",$1);
						}
						else if(var_decl_type == BOOLEAN_t){
							fprintf(writefile,".field public static %s Z\n",$1);
						}
					}
					else{
						$$->local_number = local_count;
						if(var_decl_type == DOUBLE_t){
							local_count += 2;
						}
						else{
							local_count++;
						}
					}
				}
                ;
		 
initial_array : L_BRACE literal_list R_BRACE { $$ = $2; }
			  ;

literal_list : literal_list COMMA logical_expression
				{
					struct expr_sem *ptr;
					for( ptr=$1; (ptr->next)!=0; ptr=(ptr->next) );				
					ptr->next = $3;
					$$ = $1;
				}
             | logical_expression
				{
					$$ = $1;
				}
             |
             ;

const_decl 	: CONST scalar_type const_list SEMICOLON
			{
				struct SymNode *newNode;				
				struct constParam *ptr;
				for( ptr=$3; ptr!=0; ptr=(ptr->next) ){
					if( verifyRedeclaration( symbolTable, ptr->name, scope ) == __TRUE ){//no redeclare
						if( ptr->value->category != $2->type ){//type different
							if( !(($2->type==FLOAT_t || $2->type == DOUBLE_t ) && ptr->value->category==INTEGER_t) ) {
								if(!($2->type==DOUBLE_t && ptr->value->category==FLOAT_t)){	
									fprintf( stdout, "########## Error at Line#%d: const type different!! ##########\n", linenum );
									semError = __TRUE;	
								}
								else{
									newNode = createConstNode( ptr->name, scope, $2, ptr->value );
									insertTab( symbolTable, newNode );
								}
							}							
							else{
								newNode = createConstNode( ptr->name, scope, $2, ptr->value );
								insertTab( symbolTable, newNode );
							}
						}
						else{
							newNode = createConstNode( ptr->name, scope, $2, ptr->value );
							insertTab( symbolTable, newNode );
						}
					}
				}
			}
			;

const_list : const_list COMMA ID ASSIGN_OP literal_const
			{				
				if(var_decl_type == FLOAT_t && $5->category == INTEGER_t){
					$5->value.floatVal = $5->value.integerVal;
				}
				else if(var_decl_type == DOUBLE_t && $5->category == INTEGER_t){
					$5->value.doubleVal = $5->value.integerVal;
				}
				else if(var_decl_type == DOUBLE_t && $5->category == FLOAT_t){
					$5->value.doubleVal = $5->value.floatVal;
				}
				addConstParam( $1, createConstParam( $5, $3 ) );
				$$ = $1;
			}
		   | ID ASSIGN_OP literal_const
			{
				if(var_decl_type == FLOAT_t && $3->category == INTEGER_t){
					$3->value.floatVal = $3->value.integerVal;
				}
				else if(var_decl_type == DOUBLE_t && $3->category == INTEGER_t){
					$3->value.doubleVal = $3->value.integerVal;
				}
				else if(var_decl_type == DOUBLE_t && $3->category == FLOAT_t){
					$3->value.doubleVal = $3->value.floatVal;
				}
				$$ = createConstParam( $3, $1 );	
			}
		   ;

array_decl : ID dim 
			{
				$$ = createParam( createIdList( $1 ), $2 );
			}
		   ;

dim : dim ML_BRACE INT_CONST MR_BRACE
		{
			if( $3 == 0 ){
				fprintf( stdout, "########## Error at Line#%d: array size error!! ##########\n", linenum );
				semError = __TRUE;
			}
			else
				increaseArrayDim( $1, 0, $3 );			
		}
	| ML_BRACE INT_CONST MR_BRACE	
		{
			if( $2 == 0 ){
				fprintf( stdout, "########## Error at Line#%d: array size error!! ##########\n", linenum );
				semError = __TRUE;
			}			
			else{		
				$$ = createPType( VOID_t ); 			
				increaseArrayDim( $$, 0, $2 );
			}		
		}
	;
	
compound_statement : {
						scope++; 
						if(function_flag == 0){
							temp_local_count = local_count;
						}
						else{
							function_flag = 0;
						}
					}
					L_BRACE var_const_stmt_list R_BRACE
					{ 
						// print contents of current scope
						if( Opt_Symbol == 1 )
							printSymTable( symbolTable, scope );
						temp_local_count = local_count - temp_local_count;
						local_count -= temp_local_count;
						deleteScope( symbolTable, scope );	// leave this scope, delete...
						scope--; 
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
					{
						// check if LHS exists
						__BOOLEAN flagLHS = verifyExistence( symbolTable, $1, scope, __TRUE );
						// id RHS is not dereferenced, check and deference
						__BOOLEAN flagRHS = __TRUE;
						if( $3->isDeref == __FALSE ) {
							flagRHS = verifyExistence( symbolTable, $3, scope, __FALSE );
						}
						// if both LHS and RHS are exists, verify their type
						if( flagLHS==__TRUE && flagRHS==__TRUE )
							verifyAssignmentTypeMatch( $1, $3 );
						
						if($3->isload == __FALSE){
							if($3->node == NULL){
								if($3->constvalue->category == INTEGER_t){
									fprintf(writefile,"ldc %d\n",$3->constvalue->value.integerVal);
								}
								else if ($3->constvalue->category == FLOAT_t){
									fprintf(writefile,"ldc %f\n",$3->constvalue->value.floatVal);
								}
								else if ($3->constvalue->category == DOUBLE_t){
									fprintf(writefile,"ldc2_w %lf\n",$3->constvalue->value.doubleVal);
								}
								else if ($3->constvalue->category == BOOLEAN_t){
									if($3->constvalue->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($3->node->category == CONSTANT_t){
								if($3->pType->type == INTEGER_t){
									fprintf(writefile,"ldc %d\n",$3->node->attribute->constVal->value.integerVal);
								}
								else if($3->pType->type == FLOAT_t){
									fprintf(writefile,"ldc %f\n",$3->node->attribute->constVal->value.floatVal);
								}
								else if($3->pType->type == DOUBLE_t){
									fprintf(writefile,"ldc2_w %lf\n",$3->node->attribute->constVal->value.doubleVal);
								}
								else if($3->pType->type == BOOLEAN_t){
									if($3->node->attribute->constVal->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($3->node->scope == 0){
								if($3->node->category == FUNCTION_t){
								}
								else if($3->pType->type == INTEGER_t){
									fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$3->node->name);
								}
								else if($3->pType->type == FLOAT_t){
									fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$3->node->name);
								}
								else if($3->pType->type == DOUBLE_t){
									fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$3->node->name);
								}
								else if($3->pType->type == BOOLEAN_t){
									fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$3->node->name);
								}
							}
							else{
								if($3->pType->type == INTEGER_t){
									fprintf(writefile,"iload %d\n",$3->node->local_number);
								}
								else if($3->pType->type == FLOAT_t){
									fprintf(writefile,"fload %d\n",$3->node->local_number);
								}
								else if($3->pType->type == DOUBLE_t){
									fprintf(writefile,"dload %d\n",$3->node->local_number);
								}
								else if($3->pType->type == BOOLEAN_t){
									fprintf(writefile,"iload %d\n",$3->node->local_number);
								}
							}
							$3->isload = __TRUE;
						}
						
						if($1->pType->type == FLOAT_t && $3->pType->type == INTEGER_t){
							fprintf(writefile,"i2f\n");
						}
						else if($1->pType->type == DOUBLE_t && $3->pType->type == INTEGER_t){
							fprintf(writefile,"i2d\n");
						}
						else if($1->pType->type == DOUBLE_t && $3->pType->type == FLOAT_t){
							fprintf(writefile,"f2d\n");
						}
						
						if($1->node->scope == 0){
							if($1->pType->type == INTEGER_t){
								fprintf(writefile,"putstatic %s/%s I\n",frontfileName,$1->node->name);
							}
							else if($1->pType->type == FLOAT_t){
								fprintf(writefile,"putstatic %s/%s F\n",frontfileName,$1->node->name);
							}
							else if($1->pType->type == DOUBLE_t){
								fprintf(writefile,"putstatic %s/%s D\n",frontfileName,$1->node->name);
							}
							else if($1->pType->type == BOOLEAN_t){
								fprintf(writefile,"putstatic %s/%s Z\n",frontfileName,$1->node->name);
							}
						}
						else{
							if($1->pType->type == INTEGER_t || $1->pType->type == BOOLEAN_t){
								fprintf(writefile,"istore %d\n",$1->node->local_number);
							}
							else if($1->pType->type == FLOAT_t){
								fprintf(writefile,"fstore %d\n",$1->node->local_number);
							}
							else if($1->pType->type == DOUBLE_t){
								fprintf(writefile,"dstore %d\n",$1->node->local_number);
							}
						}
					}
				 | PRINT 
				 {
					fprintf(writefile,"getstatic java/lang/System/out Ljava/io/PrintStream;\n");
				 }
				 logical_expression SEMICOLON 
				 { 
					verifyScalarExpr( $3, "print" ); 
					if($3->isload == __FALSE){
						if($3->node == NULL){
							if($3->constvalue->category == INTEGER_t){
								fprintf(writefile,"ldc %d\n",$3->constvalue->value.integerVal);
							}
							else if ($3->constvalue->category == FLOAT_t){
								fprintf(writefile,"ldc %f\n",$3->constvalue->value.floatVal);
							}
							else if ($3->constvalue->category == DOUBLE_t){
								fprintf(writefile,"ldc2_w %lf\n",$3->constvalue->value.doubleVal);
							}
							else if ($3->constvalue->category == BOOLEAN_t){
								if($3->constvalue->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
							else if ($3->constvalue->category == STRING_t){
								fprintf(writefile,"ldc \"%s\"\n",$3->constvalue->value.stringVal);
							}
							
							if($3->pType->type == INTEGER_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(I)V\n");
							}
							else if($3->pType->type == FLOAT_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(F)V\n");
							}
							else if($3->pType->type == DOUBLE_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(D)V\n");
							}
							else if($3->pType->type == BOOLEAN_t){
								if($3->node->attribute->constVal->value.booleanVal == __TRUE){
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
								}
								else{
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
								}
							}
							else if ($3->pType->type == STRING_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
							}
						}
						else if($3->node->category == CONSTANT_t){
							if($3->pType->type == INTEGER_t){
								fprintf(writefile,"ldc %d\n",$3->node->attribute->constVal->value.integerVal);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(I)V\n");
							}
							else if($3->pType->type == FLOAT_t){
								fprintf(writefile,"ldc %f\n",$3->node->attribute->constVal->value.floatVal);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(F)V\n");
							}
							else if($3->pType->type == DOUBLE_t){
								fprintf(writefile,"ldc2_w %lf\n",$3->node->attribute->constVal->value.doubleVal);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(D)V\n");
							}
							else if($3->pType->type == BOOLEAN_t){
								if($3->node->attribute->constVal->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
								}
							}
							else if ($3->pType->type == STRING_t){
								fprintf(writefile,"ldc \"%s\"\n",$3->node->attribute->constVal->value.stringVal);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
							}
						}
						else if($3->node->scope == 0){
							if($3->node->category == FUNCTION_t){
								if($3->pType->type == INTEGER_t){
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(I)V\n");
								}
								else if($3->pType->type == FLOAT_t){
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(F)V\n");
								}
								else if($3->pType->type == DOUBLE_t){
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(D)V\n");
								}
								else if($3->pType->type == BOOLEAN_t){
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
								}
							}
							else if($3->pType->type == INTEGER_t){
								fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$3->node->name);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(I)V\n");
							}
							else if($3->pType->type == FLOAT_t){
								fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$3->node->name);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(F)V\n");
							}
							else if($3->pType->type == DOUBLE_t){
								fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$3->node->name);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(D)V\n");
							}
							else if($3->pType->type == BOOLEAN_t){
								fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$3->node->name);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
							}
						}
						else{
							if($3->pType->type == INTEGER_t){
								fprintf(writefile,"iload %d\n",$3->node->local_number);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(I)V\n");
							}
							else if($3->pType->type == FLOAT_t){
								fprintf(writefile,"fload %d\n",$3->node->local_number);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(F)V\n");
							}
							else if($3->pType->type == DOUBLE_t){
								fprintf(writefile,"dload %d\n",$3->node->local_number);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(D)V\n");
							}
							else if($3->pType->type == BOOLEAN_t){
								fprintf(writefile,"iload %d\n",$3->node->local_number);
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
							}
						}
						$3->isload = __TRUE;
					}
					else{
						if($3->node == NULL){
							if($3->pType->type == INTEGER_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(I)V\n");
							}
							else if ($3->pType->type == FLOAT_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(F)V\n");
							}
							else if ($3->pType->type == DOUBLE_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(D)V\n");
							}
							else if ($3->pType->type == BOOLEAN_t){
								if($3->constvalue->value.booleanVal == __TRUE){
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
								}
								else{
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
								}
							}
							else if ($3->constvalue->category == STRING_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
							}
						}
						else if($3->node->category == CONSTANT_t){
							if($3->pType->type == INTEGER_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(I)V\n");
							}
							else if($3->pType->type == FLOAT_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(F)V\n");
							}
							else if($3->pType->type == DOUBLE_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(D)V\n");
							}
							else if($3->pType->type == BOOLEAN_t){
								if($3->node->attribute->constVal->value.booleanVal == __TRUE){
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
								}
								else{
									fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
								}
							}
							else if ($3->pType->type == STRING_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
							}
						}
						else if($3->node->scope == 0){
							if($3->pType->type == INTEGER_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(I)V\n");
							}
							else if($3->pType->type == FLOAT_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(F)V\n");
							}
							else if($3->pType->type == DOUBLE_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(D)V\n");
							}
							else if($3->pType->type == BOOLEAN_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
							}
						}
						else{
							if($3->pType->type == INTEGER_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(I)V\n");
							}
							else if($3->pType->type == FLOAT_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(F)V\n");
							}
							else if($3->pType->type == DOUBLE_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(D)V\n");
							}
							else if($3->pType->type == BOOLEAN_t){
								fprintf(writefile,"invokevirtual java/io/PrintStream/print(Z)V\n");
							}
						}
					}
				 }
				 | READ variable_reference SEMICOLON 
					{ 
						if( verifyExistence( symbolTable, $2, scope, __TRUE ) == __TRUE ){
							verifyScalarExpr( $2, "read" );
							fprintf(writefile,"getstatic %s/_sc Ljava/util/Scanner;\n",frontfileName);
							if($2->node->scope == 0){
								if($2->pType->type == INTEGER_t){
									fprintf(writefile,"invokevirtual java/util/Scanner/nextInt()I\n");
									fprintf(writefile,"putstatic %s/%s I\n",frontfileName,$2->node->name);
								}
								else if($2->pType->type == FLOAT_t){
									fprintf(writefile,"invokevirtual java/util/Scanner/nextFloat()F\n");
									fprintf(writefile,"putstatic %s/%s F\n",frontfileName,$2->node->name);
								}
								else if($2->pType->type == DOUBLE_t){
									fprintf(writefile,"invokevirtual java/util/Scanner/nextDouble()D\n");
									fprintf(writefile,"putstatic %s/%s D\n",frontfileName,$2->node->name);
								}
								else if($2->pType->type == BOOLEAN_t){
									fprintf(writefile,"invokevirtual java/util/Scanner/nextBoolean()Z\n");
									fprintf(writefile,"putstatic %s/%s Z\n",frontfileName,$2->node->name);
								}
							}
							else{
								if($2->pType->type == INTEGER_t){
									fprintf(writefile,"invokevirtual java/util/Scanner/nextInt()I\n");
									fprintf(writefile,"istore %d\n",$2->node->local_number);
								}
								else if($2->pType->type == FLOAT_t){
									fprintf(writefile,"invokevirtual java/util/Scanner/nextFloat()F\n");
									fprintf(writefile,"fstore %d\n",$2->node->local_number);
								}
								else if($2->pType->type == DOUBLE_t){
									fprintf(writefile,"invokevirtual java/util/Scanner/nextDouble()D\n");
									fprintf(writefile,"dstore %d\n",$2->node->local_number);
								}
								else if($2->pType->type == BOOLEAN_t){
									fprintf(writefile,"invokevirtual java/util/Scanner/nextBoolean()Z\n");
									fprintf(writefile,"istore %d\n",$2->node->local_number);
								}
							}
							$2->isload = __TRUE;
						}						 
					}
				 ;

conditional_statement : IF L_PAREN conditional_if  R_PAREN compound_statement
						{
							int temp = if_pop();
							fprintf(writefile,"Lelse_%d:\n",temp);
						}
					  | IF L_PAREN conditional_if  R_PAREN compound_statement
						ELSE 
						{	
							int temp = if_pop();
							fprintf(writefile,"goto Lexit_%d\n",temp);
							fprintf(writefile,"Lelse_%d:\n",temp);		
							if_push(temp);
						}
						compound_statement
						{
							int temp = if_pop();
							fprintf(writefile,"Lexit_%d:\n",temp);
						}
					  ;
conditional_if : logical_expression 
				{ 
					verifyBooleanExpr( $1, "if" ); 
					if($1->isload == __FALSE){
						if($1->node == NULL){
							if($1->constvalue->category == BOOLEAN_t){
								if($1->constvalue->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($1->node->category == CONSTANT_t){
							if($1->pType->type == BOOLEAN_t){
								if($1->node->attribute->constVal->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($1->node->scope == 0){
							if($1->node->category == FUNCTION_t){
							}
							else if($1->pType->type == BOOLEAN_t){
								fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$1->node->name);
							}
						}
						else{
							if($1->pType->type == BOOLEAN_t){
								fprintf(writefile,"iload %d\n",$1->node->local_number);
							}
						}
						$1->isload = __TRUE;
					}
					    
					fprintf(writefile,"ifeq Lelse_%d\n",elselabel_count);
					if_push(elselabel_count);
					elselabel_count++;
				}
				;					  

				
while_statement : WHILE L_PAREN
				{
					fprintf(writefile,"Lwbegin_%d:\n",whilelabel_count);
					while_push(whilelabel_count);
					whilelabel_count++;
				} 
				logical_expression 
				{ 
					verifyBooleanExpr( $4, "while" );
					if($4->isload == __FALSE){
						if($4->node == NULL){
							if($4->constvalue->category == BOOLEAN_t){
								if($4->constvalue->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($4->node->category == CONSTANT_t){
							if($4->pType->type == BOOLEAN_t){
								if($4->node->attribute->constVal->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($4->node->scope == 0){
							if($4->node->category == FUNCTION_t){
							}
							else if($4->pType->type == BOOLEAN_t){
								fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$4->node->name);
							}
						}
						else{
							if($4->pType->type == BOOLEAN_t){
								fprintf(writefile,"iload %d\n",$4->node->local_number);
							}
						}
						$4->isload = __TRUE;
					}
					int temp = while_pop();
					fprintf(writefile,"ifeq Lwexit_%d\n",temp);
					while_push(temp);
				} 
				R_PAREN 
				{ inloop++; }
				compound_statement 
				{ 
					inloop--; 
					int temp = while_pop();
					fprintf(writefile,"goto Lwbegin_%d\n",temp);
					fprintf(writefile,"Lwexit_%d:\n",temp);
				}
				| { inloop++; } DO 
					{
						fprintf(writefile,"Lwbegin_%d:\n",whilelabel_count);
						while_push(whilelabel_count);
						whilelabel_count++;
					}
					compound_statement WHILE L_PAREN logical_expression R_PAREN SEMICOLON  
					{ 
						verifyBooleanExpr( $7, "while" );
						if($7->isload == __FALSE){
							if($7->node == NULL){
								if($7->constvalue->category == BOOLEAN_t){
									if($7->constvalue->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($7->node->category == CONSTANT_t){
								if($7->pType->type == BOOLEAN_t){
									if($7->node->attribute->constVal->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($7->node->scope == 0){
								if($7->node->category == FUNCTION_t){
								}
								else if($7->pType->type == BOOLEAN_t){
									fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$7->node->name);
								}
							}
							else{
								if($7->pType->type == BOOLEAN_t){
									fprintf(writefile,"iload %d\n",$7->node->local_number);
								}
							}
							$7->isload = __TRUE;
						}
						int temp = while_pop();
						fprintf(writefile,"ifeq Lwexit_%d\n",temp);
						fprintf(writefile,"goto Lwbegin_%d\n",temp);
						fprintf(writefile,"Lwexit_%d:\n",temp);
						inloop--; 
					}
				;


				
for_statement : FOR L_PAREN initial_expression SEMICOLON 
				{
					fprintf(writefile,"Lfbegin_%d:\n",forlabel_count);
					for_push(forlabel_count);
					forlabel_count++;
				}
				control_expression SEMICOLON
				{
					while(control_counter > 1){
						fprintf(writefile,"iand\n");
						control_counter--;
					}
					control_counter = 0;
					int temp = for_pop();
					fprintf(writefile,"ifeq Lfexit_%d\n",temp);
					fprintf(writefile,"goto Lftemp_%d\n",temp);
					fprintf(writefile,"Lfinc_%d:\n",temp);
					for_push(temp);
				}
				increment_expression R_PAREN  
				{ 
					inloop++;
					int temp = for_pop();
					fprintf(writefile,"goto Lfbegin_%d\n",temp);
					fprintf(writefile,"Lftemp_%d:\n",temp);
					for_push(temp);
				}
					compound_statement  
				{ 
					inloop--; 
					int temp = for_pop();
					fprintf(writefile,"goto Lfinc_%d\n",temp);
					fprintf(writefile,"Lfexit_%d:\n",temp);
				}
			  ;

initial_expression : initial_expression COMMA statement_for		
				   | initial_expression COMMA logical_expression
				   {
						if($3->isload == __TRUE){
							if($3->pType->type != DOUBLE_t){
								fprintf(writefile,"pop\n");
							}
							else{
								fprintf(writefile,"pop2\n");
							}
						}
				   }
				   | logical_expression	
				   {
						if($1->isload == __TRUE){
							if($1->pType->type != DOUBLE_t){
								fprintf(writefile,"pop\n");
							}
							else{
								fprintf(writefile,"pop2\n");
							}
						}
				   }
				   | statement_for
				   |
				   ;

control_expression : control_expression COMMA statement_for
				   {
						fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
						semError = __TRUE;	
				   }
				   | control_expression COMMA logical_expression
				   {
						if( $3->pType->type != BOOLEAN_t ){
							fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
							semError = __TRUE;	
						}
						
						if($3->isload == __FALSE){
							if($3->node == NULL){
								if($3->constvalue->category == BOOLEAN_t){
									if($3->constvalue->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($3->node->category == CONSTANT_t){
								if($3->pType->type == BOOLEAN_t){
									if($3->node->attribute->constVal->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($3->node->scope == 0){
								if($3->node->category == FUNCTION_t){
								}
								else if($3->pType->type == BOOLEAN_t){
									fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$3->node->name);
								}
							}
							else{
								if($3->pType->type == BOOLEAN_t){
									fprintf(writefile,"iload %d\n",$3->node->local_number);
								}
							}
							$3->isload = __TRUE;
						}
						control_counter++;
				   }
				   | logical_expression 
					{ 
						if( $1->pType->type != BOOLEAN_t ){
							fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
							semError = __TRUE;	
						}
						
						if($1->isload == __FALSE){
							if($1->node == NULL){
								if($1->constvalue->category == BOOLEAN_t){
									if($1->constvalue->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($1->node->category == CONSTANT_t){
								if($1->pType->type == BOOLEAN_t){
									if($1->node->attribute->constVal->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($1->node->scope == 0){
								if($1->node->category == FUNCTION_t){
								}
								else if($1->pType->type == BOOLEAN_t){
									fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$1->node->name);
								}
							}
							else{
								if($1->pType->type == BOOLEAN_t){
									fprintf(writefile,"iload %d\n",$1->node->local_number);
								}
							}
							$1->isload = __TRUE;
						}
						control_counter++;
					}
				   | statement_for
				   {
						fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
						semError = __TRUE;	
				   }
				   |
				   ;

increment_expression : increment_expression COMMA statement_for
					 | increment_expression COMMA logical_expression
					 {
						if($3->isload == __TRUE){
							if($3->pType->type != DOUBLE_t){
								fprintf(writefile,"pop\n");
							}
							else{
								fprintf(writefile,"pop2\n");
							}
						}
					 }
					 | logical_expression
					 {
						if($1->isload == __TRUE){
							if($1->pType->type != DOUBLE_t){
								fprintf(writefile,"pop\n");
							}
							else{
								fprintf(writefile,"pop2\n");
							}
						}
					 }
					 | statement_for
					 |
					 ;

statement_for 	: variable_reference ASSIGN_OP logical_expression
					{
						// check if LHS exists
						__BOOLEAN flagLHS = verifyExistence( symbolTable, $1, scope, __TRUE );
						// id RHS is not dereferenced, check and deference
						__BOOLEAN flagRHS = __TRUE;
						if( $3->isDeref == __FALSE ) {
							flagRHS = verifyExistence( symbolTable, $3, scope, __FALSE );
						}
						// if both LHS and RHS are exists, verify their type
						if( flagLHS==__TRUE && flagRHS==__TRUE )
							verifyAssignmentTypeMatch( $1, $3 );
						
						if($3->isload == __FALSE){
							if($3->node == NULL){
								if($3->constvalue->category == INTEGER_t){
									fprintf(writefile,"ldc %d\n",$3->constvalue->value.integerVal);
								}
								else if ($3->constvalue->category == FLOAT_t){
									fprintf(writefile,"ldc %f\n",$3->constvalue->value.floatVal);
								}
								else if ($3->constvalue->category == DOUBLE_t){
									fprintf(writefile,"ldc2_w %lf\n",$3->constvalue->value.doubleVal);
								}
								else if ($3->constvalue->category == BOOLEAN_t){
									if($3->constvalue->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($3->node->category == CONSTANT_t){
								if($3->pType->type == INTEGER_t){
									fprintf(writefile,"ldc %d\n",$3->node->attribute->constVal->value.integerVal);
								}
								else if($3->pType->type == FLOAT_t){
									fprintf(writefile,"ldc %f\n",$3->node->attribute->constVal->value.floatVal);
								}
								else if($3->pType->type == DOUBLE_t){
									fprintf(writefile,"ldc2_w %lf\n",$3->node->attribute->constVal->value.doubleVal);
								}
								else if($3->pType->type == BOOLEAN_t){
									if($3->node->attribute->constVal->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($3->node->scope == 0){
								if($3->node->category == FUNCTION_t){
								}
								else if($3->pType->type == INTEGER_t){
									fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$3->node->name);
								}
								else if($3->pType->type == FLOAT_t){
									fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$3->node->name);
								}
								else if($3->pType->type == DOUBLE_t){
									fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$3->node->name);
								}
								else if($3->pType->type == BOOLEAN_t){
									fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$3->node->name);
								}
							}
							else{
								if($3->pType->type == INTEGER_t){
									fprintf(writefile,"iload %d\n",$3->node->local_number);
								}
								else if($3->pType->type == FLOAT_t){
									fprintf(writefile,"fload %d\n",$3->node->local_number);
								}
								else if($3->pType->type == DOUBLE_t){
									fprintf(writefile,"dload %d\n",$3->node->local_number);
								}
								else if($3->pType->type == BOOLEAN_t){
									fprintf(writefile,"iload %d\n",$3->node->local_number);
								}
							}
							$3->isload = __TRUE;
						}
						
						if($1->pType->type == FLOAT_t && $3->pType->type == INTEGER_t){
							fprintf(writefile,"i2f\n");
						}
						else if($1->pType->type == DOUBLE_t && $3->pType->type == INTEGER_t){
							fprintf(writefile,"i2d\n");
						}
						else if($1->pType->type == DOUBLE_t && $3->pType->type == FLOAT_t){
							fprintf(writefile,"f2d\n");
						}
						
						if($1->node->scope == 0){
							if($1->pType->type == INTEGER_t){
								fprintf(writefile,"putstatic %s/%s I\n",frontfileName,$1->node->name);
							}
							else if($1->pType->type == FLOAT_t){
								fprintf(writefile,"putstatic %s/%s F\n",frontfileName,$1->node->name);
							}
							else if($1->pType->type == DOUBLE_t){
								fprintf(writefile,"putstatic %s/%s D\n",frontfileName,$1->node->name);
							}
							else if($1->pType->type == BOOLEAN_t){
								fprintf(writefile,"putstatic %s/%s Z\n",frontfileName,$1->node->name);
							}
						}
						else{
							if($1->pType->type == INTEGER_t || $1->pType->type == BOOLEAN_t){
								fprintf(writefile,"istore %d\n",$1->node->local_number);
							}
							else if($1->pType->type == FLOAT_t){
								fprintf(writefile,"fstore %d\n",$1->node->local_number);
							}
							else if($1->pType->type == DOUBLE_t){
								fprintf(writefile,"dstore %d\n",$1->node->local_number);
							}
						}
					}
					;
					 
					 
function_invoke_statement : ID L_PAREN logical_expression_list R_PAREN SEMICOLON
							{
								struct expr_sem *temp3 = verifyFuncInvoke( $1, $3, symbolTable, scope );
								struct expr_sem *temp1 = $3;
								struct PTypeList *temp2 = temp3->node->attribute->formalParam->params;
								while(temp1 != NULL && temp2 != NULL){
									if(temp1->isload == __FALSE){
										if(temp1->node == NULL){
											if(temp1->constvalue->category == INTEGER_t){
												fprintf(writefile,"ldc %d\n",temp1->constvalue->value.integerVal);
											}
											else if (temp1->constvalue->category == FLOAT_t){
												fprintf(writefile,"ldc %f\n",temp1->constvalue->value.floatVal);
											}
											else if (temp1->constvalue->category == DOUBLE_t){
												fprintf(writefile,"ldc2_w %lf\n",temp1->constvalue->value.doubleVal);
											}
											else if (temp1->constvalue->category == BOOLEAN_t){
												if(temp1->constvalue->value.booleanVal == __TRUE){
													fprintf(writefile,"iconst_1\n");
												}
												else{
													fprintf(writefile,"iconst_0\n");
												}
											}
										}
										else if(temp1->node->category == CONSTANT_t){
											if(temp1->pType->type == INTEGER_t){
												fprintf(writefile,"ldc %d\n",temp1->node->attribute->constVal->value.integerVal);
											}
											else if(temp1->pType->type == FLOAT_t){
												fprintf(writefile,"ldc %f\n",temp1->node->attribute->constVal->value.floatVal);
											}
											else if(temp1->pType->type == DOUBLE_t){
												fprintf(writefile,"ldc2_w %lf\n",temp1->node->attribute->constVal->value.doubleVal);
											}
											else if(temp1->pType->type == BOOLEAN_t){
												if(temp1->node->attribute->constVal->value.booleanVal == __TRUE){
													fprintf(writefile,"iconst_1\n");
												}
												else{
													fprintf(writefile,"iconst_0\n");
												}
											}
										}
										else if(temp1->node->scope == 0){
											if(temp1->node->category == FUNCTION_t){
											}
											else if(temp1->pType->type == INTEGER_t){
												fprintf(writefile,"getstatic %s/%s I\n",frontfileName,temp1->node->name);
											}
											else if(temp1->pType->type == FLOAT_t){
												fprintf(writefile,"getstatic %s/%s F\n",frontfileName,temp1->node->name);
											}
											else if(temp1->pType->type == DOUBLE_t){
												fprintf(writefile,"getstatic %s/%s D\n",frontfileName,temp1->node->name);
											}
											else if(temp1->pType->type == BOOLEAN_t){
												fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,temp1->node->name);
											}
										}
										else{
											if(temp1->pType->type == INTEGER_t){
												fprintf(writefile,"iload %d\n",temp1->node->local_number);
											}
											else if(temp1->pType->type == FLOAT_t){
												fprintf(writefile,"fload %d\n",temp1->node->local_number);
											}
											else if(temp1->pType->type == DOUBLE_t){
												fprintf(writefile,"dload %d\n",temp1->node->local_number);
											}
											else if(temp1->pType->type == BOOLEAN_t){
												fprintf(writefile,"iload %d\n",temp1->node->local_number);
											}
										}
										temp1->isload = __TRUE;
									}
									
									if(temp2->value->type == FLOAT_t && temp1->pType->type == INTEGER_t){
										fprintf(writefile,"i2f\n");
									}
									else if(temp2->value->type == DOUBLE_t && temp1->pType->type == INTEGER_t){
										fprintf(writefile,"i2d\n");
									}
									else if(temp2->value->type == DOUBLE_t && temp1->pType->type == FLOAT_t){
										fprintf(writefile,"f2d\n");
									}
									
									temp1 = temp1->next;
									temp2 = temp2->next;
								}
								fprintf(writefile,"invokestatic %s/%s(",frontfileName,$1);
								struct PTypeList *temp = temp3->node->attribute->formalParam->params;
								while(temp != NULL){
									if(temp->value->type == INTEGER_t){
										fprintf(writefile,"I");
									}
									else if(temp->value->type == FLOAT_t){
										fprintf(writefile,"F");
									}
									else if(temp->value->type == DOUBLE_t){
										fprintf(writefile,"D");
									}
									else if(temp->value->type == BOOLEAN_t){
										fprintf(writefile,"Z");
									}
									temp = temp->next;
								}
								if(temp3->pType->type == INTEGER_t){
									fprintf(writefile,")I\n");
								}
								else if(temp3->pType->type == FLOAT_t){
									fprintf(writefile,")F\n");
								}
								else if(temp3->pType->type == DOUBLE_t){
									fprintf(writefile,")D\n");
								}
								else if(temp3->pType->type == BOOLEAN_t){
									fprintf(writefile,")Z\n");
								}
								else if(temp3->pType->type == VOID_t){
									fprintf(writefile,")V\n");
								}
								
								if(temp3->pType->type == INTEGER_t || temp3->pType->type == FLOAT_t || temp3->pType->type == BOOLEAN_t){
									fprintf(writefile,"pop\n");
								}	
								else if(temp3->pType->type == DOUBLE_t){
									fprintf(writefile,"pop2\n");
								}
							}
						  | ID L_PAREN R_PAREN SEMICOLON
							{
								struct expr_sem *temp =	verifyFuncInvoke( $1, 0, symbolTable, scope );
								if(temp->pType->type == VOID_t){
									fprintf(writefile,"invokestatic %s/%s()V\n",frontfileName,$1);
								}
								else if(temp->pType->type == INTEGER_t){
									fprintf(writefile,"invokestatic %s/%s()I\n",frontfileName,$1);
								}
								else if(temp->pType->type == FLOAT_t){
									fprintf(writefile,"invokestatic %s/%s()F\n",frontfileName,$1);
								}
								else if(temp->pType->type == DOUBLE_t){
									fprintf(writefile,"invokestatic %s/%s()D\n",frontfileName,$1);
								}
								else if(temp->pType->type == BOOLEAN_t){
									fprintf(writefile,"invokestatic %s/%s()Z\n",frontfileName,$1);
								}
								
								if(temp->pType->type == INTEGER_t || temp->pType->type == FLOAT_t || temp->pType->type == BOOLEAN_t){
									fprintf(writefile,"pop\n");
								}
								else if(temp->pType->type == DOUBLE_t){
									fprintf(writefile,"pop2\n");
								}
							}
						  ;

jump_statement : CONTINUE SEMICOLON
				{
					if( inloop <= 0){
						fprintf( stdout, "########## Error at Line#%d: continue can't appear outside of loop ##########\n", linenum ); semError = __TRUE;
					}
				}
			   | BREAK SEMICOLON 
				{
					if( inloop <= 0){
						fprintf( stdout, "########## Error at Line#%d: break can't appear outside of loop ##########\n", linenum ); semError = __TRUE;
					}
				}
			   | RETURN logical_expression SEMICOLON
				{
					verifyReturnStatement( $2, funcReturn );
					if($2->isload == __FALSE){
						if($2->node == NULL){
							if($2->constvalue->category == INTEGER_t){
								fprintf(writefile,"ldc %d\n",$2->constvalue->value.integerVal);
							}
							else if ($2->constvalue->category == FLOAT_t){
								fprintf(writefile,"ldc %f\n",$2->constvalue->value.floatVal);
							}
							else if ($2->constvalue->category == DOUBLE_t){
								fprintf(writefile,"ldc2_w %lf\n",$2->constvalue->value.doubleVal);
							}
							else if ($2->constvalue->category == BOOLEAN_t){
								if($2->constvalue->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($2->node->category == CONSTANT_t){
							if($2->pType->type == INTEGER_t){
								fprintf(writefile,"ldc %d\n",$2->node->attribute->constVal->value.integerVal);
							}
							else if($2->pType->type == FLOAT_t){
								fprintf(writefile,"ldc %f\n",$2->node->attribute->constVal->value.floatVal);
							}
							else if($2->pType->type == DOUBLE_t){
								fprintf(writefile,"ldc2_w %lf\n",$2->node->attribute->constVal->value.doubleVal);
							}
							else if($2->pType->type == BOOLEAN_t){
								if($2->node->attribute->constVal->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($2->node->scope == 0){
							if($2->node->category == FUNCTION_t){
							}
							else if($2->pType->type == INTEGER_t){
								fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$2->node->name);
							}
							else if($2->pType->type == FLOAT_t){
								fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$2->node->name);
							}
							else if($2->pType->type == DOUBLE_t){
								fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$2->node->name);
							}
							else if($2->pType->type == BOOLEAN_t){
								fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$2->node->name);
							}
						}
						else{
							if($2->pType->type == INTEGER_t){
								fprintf(writefile,"iload %d\n",$2->node->local_number);
							}
							else if($2->pType->type == FLOAT_t){
								fprintf(writefile,"fload %d\n",$2->node->local_number);
							}
							else if($2->pType->type == DOUBLE_t){
								fprintf(writefile,"dload %d\n",$2->node->local_number);
							}
							else if($2->pType->type == BOOLEAN_t){
								fprintf(writefile,"iload %d\n",$2->node->local_number);
							}
						}
						$2->isload = __TRUE;
					}
					
					if(funcReturn->type == FLOAT_t && $2->pType->type == INTEGER_t){
						fprintf(writefile,"i2f\n");
					}
					else if(funcReturn->type == DOUBLE_t && $2->pType->type == INTEGER_t){
						fprintf(writefile,"i2d\n");
					}
					else if(funcReturn->type == DOUBLE_t && $2->pType->type == FLOAT_t){
						fprintf(writefile,"f2d\n");
					}
					
					if(mainflag == __TRUE){
						if($2->isload == __TRUE){
							if($2->pType->type != DOUBLE_t){
								fprintf(writefile,"pop\n");
							}
							else{
								fprintf(writefile,"pop2\n");
							}
						}
						mainreturnflag = __TRUE;
						fprintf(writefile,"return\n");
					} 
					else if(funcReturn->type == VOID_t){
						fprintf(writefile,"return\n");
					}
					else if(funcReturn->type == INTEGER_t || funcReturn->type == BOOLEAN_t){
						fprintf(writefile,"ireturn\n");
					}
					else if(funcReturn->type == FLOAT_t){
						fprintf(writefile,"freturn\n");
					}
					else if(funcReturn->type == DOUBLE_t){
						fprintf(writefile,"dreturn\n");
					}
				}
			   ;

variable_reference : ID
					{
						$$ = createExprSem( symbolTable,$1,scope,__FALSE);
					}
				   | variable_reference dimension
					{	
						increaseDim( $1, $2 );
						$$ = $1;
					}
				   ;

dimension : ML_BRACE arithmetic_expression MR_BRACE
			{
				$$ = verifyArrayIndex( $2 );
			}
		  ;
		  
logical_expression : logical_expression OR_OP 
					{
						if($1->isload == __FALSE){
							if($1->node == NULL){
								if($1->constvalue->category == BOOLEAN_t){
									if($1->constvalue->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($1->node->category == CONSTANT_t){
								if($1->pType->type == BOOLEAN_t){
									if($1->node->attribute->constVal->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($1->node->scope == 0){
								if($1->node->category == FUNCTION_t){
								}
								else if($1->pType->type == BOOLEAN_t){
									fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$1->node->name);
								}
							}
							else{
								if($1->pType->type == BOOLEAN_t){
									fprintf(writefile,"iload %d\n",$1->node->local_number);
								}
							}
							$1->isload = __TRUE;
						}
					}
					logical_term
					{
						verifyAndOrOp( $1, OR_t, $4 );
						
						if($4->isload == __FALSE){
							if($4->node == NULL){
								if($4->constvalue->category == BOOLEAN_t){
									if($4->constvalue->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($4->node->category == CONSTANT_t){
								if($4->pType->type == BOOLEAN_t){
									if($4->node->attribute->constVal->value.booleanVal == __TRUE){
										fprintf(writefile,"iconst_1\n");
									}
									else{
										fprintf(writefile,"iconst_0\n");
									}
								}
							}
							else if($4->node->scope == 0){
								if($4->node->category == FUNCTION_t){
								}
								else if($4->pType->type == BOOLEAN_t){
									fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$4->node->name);
								}
							}
							else{
								if($4->pType->type == BOOLEAN_t){
									fprintf(writefile,"iload %d\n",$4->node->local_number);
								}
							}
							$4->isload = __TRUE;
						}
						
						if($1->pType->type == BOOLEAN_t){
							fprintf(writefile,"ior\n");
						}
						
						$$ = $1;
					}
				   | logical_term { $$ = $1; }
				   ;

logical_term : logical_term AND_OP 
				{
					if($1->isload == __FALSE){
						if($1->node == NULL){
							if($1->constvalue->category == BOOLEAN_t){
								if($1->constvalue->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($1->node->category == CONSTANT_t){
							if($1->pType->type == BOOLEAN_t){
								if($1->node->attribute->constVal->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($1->node->scope == 0){
							if($1->node->category == FUNCTION_t){
							}
							else if($1->pType->type == BOOLEAN_t){
								fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$1->node->name);
							}
						}
						else{
							if($1->pType->type == BOOLEAN_t){
								fprintf(writefile,"iload %d\n",$1->node->local_number);
							}
						}
						$1->isload = __TRUE;
					}
				}
				logical_factor
				{
					verifyAndOrOp( $1, AND_t, $4 );
					
					if($4->isload == __FALSE){
						if($4->node == NULL){
							if($4->constvalue->category == BOOLEAN_t){
								if($4->constvalue->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($4->node->category == CONSTANT_t){
							if($4->pType->type == BOOLEAN_t){
								if($4->node->attribute->constVal->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($4->node->scope == 0){
							if($4->node->category == FUNCTION_t){
							}
							else if($4->pType->type == BOOLEAN_t){
								fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$4->node->name);
							}
						}
						else{
							if($4->pType->type == BOOLEAN_t){
								fprintf(writefile,"iload %d\n",$4->node->local_number);
							}
						}
						$4->isload = __TRUE;
					}
					
					if($1->pType->type == BOOLEAN_t){
						fprintf(writefile,"iand\n");
					}
					
					$$ = $1;
				}
			 | logical_factor { $$ = $1; }
			 ;

logical_factor : NOT_OP logical_factor
				{
					verifyUnaryNOT( $2 );
					if($2->isload == __FALSE){
						if($2->node == NULL){
							if($2->constvalue->category == BOOLEAN_t){
								if($2->constvalue->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($2->node->category == CONSTANT_t){
							if($2->pType->type == BOOLEAN_t){
								if($2->node->attribute->constVal->value.booleanVal == __TRUE){
									fprintf(writefile,"iconst_1\n");
								}
								else{
									fprintf(writefile,"iconst_0\n");
								}
							}
						}
						else if($2->node->scope == 0){
							if($2->node->category == FUNCTION_t){
							}
							else if($2->pType->type == BOOLEAN_t){
								fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$2->node->name);
							}
						}
						else{
							if($2->pType->type == BOOLEAN_t){
								fprintf(writefile,"iload %d\n",$2->node->local_number);
							}
						}
						$2->isload = __TRUE;
					}
					
					if($2->pType->type == BOOLEAN_t){
						fprintf(writefile,"iconst_1\n");
						fprintf(writefile,"ixor\n");
					}
					
					$$ = $2;
				}
			   | relation_expression { $$ = $1; }
			   ;

relation_expression : arithmetic_expression relation_operator 
					{
						if($2 == EQ_t || $2 == NE_t){
							if($1->isload == __FALSE){
								if($1->node == NULL){
									if($1->constvalue->category == INTEGER_t){
										fprintf(writefile,"ldc %d\n",$1->constvalue->value.integerVal);
									}
									else if ($1->constvalue->category == FLOAT_t){
										fprintf(writefile,"ldc %f\n",$1->constvalue->value.floatVal);
									}
									else if ($1->constvalue->category == DOUBLE_t){
										fprintf(writefile,"ldc2_w %lf\n",$1->constvalue->value.doubleVal);
									}
									else if ($1->constvalue->category == BOOLEAN_t){
										if($1->constvalue->value.booleanVal == __TRUE){
											fprintf(writefile,"iconst_1\n");
										}
										else{
											fprintf(writefile,"iconst_0\n");
										}
									}
								}
								else if($1->node->category == CONSTANT_t){
									if($1->pType->type == INTEGER_t){
										fprintf(writefile,"ldc %d\n",$1->node->attribute->constVal->value.integerVal);
									}
									else if($1->pType->type == FLOAT_t){
										fprintf(writefile,"ldc %f\n",$1->node->attribute->constVal->value.floatVal);
									}
									else if($1->pType->type == DOUBLE_t){
										fprintf(writefile,"ldc2_w %lf\n",$1->node->attribute->constVal->value.doubleVal);
									}
									else if($1->pType->type == BOOLEAN_t){
										if($1->node->attribute->constVal->value.booleanVal == __TRUE){
											fprintf(writefile,"iconst_1\n");
										}
										else{
											fprintf(writefile,"iconst_0\n");
										}
									}
								}
								else if($1->node->scope == 0){
									if($1->node->category == FUNCTION_t){
									}
									else if($1->pType->type == INTEGER_t){
										fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$1->node->name);
									}
									else if($1->pType->type == FLOAT_t){
										fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$1->node->name);
									}
									else if($1->pType->type == DOUBLE_t){
										fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$1->node->name);
									}
									else if($1->pType->type == BOOLEAN_t){
										fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$1->node->name);
									}
								}
								else{
									if($1->pType->type == INTEGER_t){
										fprintf(writefile,"iload %d\n",$1->node->local_number);
									}
									else if($1->pType->type == FLOAT_t){
										fprintf(writefile,"fload %d\n",$1->node->local_number);
									}
									else if($1->pType->type == DOUBLE_t){
										fprintf(writefile,"dload %d\n",$1->node->local_number);
									}
									else if($1->pType->type == BOOLEAN_t){
										fprintf(writefile,"iload %d\n",$1->node->local_number);
									}
								}
								$1->isload = __TRUE;
							}
						}
						else{
							if($1->isload == __FALSE){
								if($1->node == NULL){
									if($1->constvalue->category == INTEGER_t){
										fprintf(writefile,"ldc %d\n",$1->constvalue->value.integerVal);
									}
									else if ($1->constvalue->category == FLOAT_t){
										fprintf(writefile,"ldc %f\n",$1->constvalue->value.floatVal);
									}
									else if ($1->constvalue->category == DOUBLE_t){
										fprintf(writefile,"ldc2_w %lf\n",$1->constvalue->value.doubleVal);
									}
								}
								else if($1->node->category == CONSTANT_t){
									if($1->pType->type == INTEGER_t){
										fprintf(writefile,"ldc %d\n",$1->node->attribute->constVal->value.integerVal);
									}
									else if($1->pType->type == FLOAT_t){
										fprintf(writefile,"ldc %f\n",$1->node->attribute->constVal->value.floatVal);
									}
									else if($1->pType->type == DOUBLE_t){
										fprintf(writefile,"ldc2_w %lf\n",$1->node->attribute->constVal->value.doubleVal);
									}
								}
								else if($1->node->scope == 0){
									if($1->node->category == FUNCTION_t){
									}
									else if($1->pType->type == INTEGER_t){
										fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$1->node->name);
									}
									else if($1->pType->type == FLOAT_t){
										fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$1->node->name);
									}
									else if($1->pType->type == DOUBLE_t){
										fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$1->node->name);
									}
								}
								else{
									if($1->pType->type == INTEGER_t){
										fprintf(writefile,"iload %d\n",$1->node->local_number);
									}
									else if($1->pType->type == FLOAT_t){
										fprintf(writefile,"fload %d\n",$1->node->local_number);
									}
									else if($1->pType->type == DOUBLE_t){
										fprintf(writefile,"dload %d\n",$1->node->local_number);
									}
								}
								$1->isload = __TRUE;
							}
						}
					}
					arithmetic_expression
					{
						
						if($2 == EQ_t || $2 == NE_t){
							if($4->isload == __FALSE){
								if($4->node == NULL){
									if($4->constvalue->category == INTEGER_t){
										fprintf(writefile,"ldc %d\n",$4->constvalue->value.integerVal);
									}
									else if ($4->constvalue->category == FLOAT_t){
										fprintf(writefile,"ldc %f\n",$4->constvalue->value.floatVal);
									}
									else if ($4->constvalue->category == DOUBLE_t){
										fprintf(writefile,"ldc2_w %lf\n",$4->constvalue->value.doubleVal);
									}
									else if ($4->constvalue->category == BOOLEAN_t){
										if($4->constvalue->value.booleanVal == __TRUE){
											fprintf(writefile,"iconst_1\n");
										}
										else{
											fprintf(writefile,"iconst_0\n");
										}
									}
								}
								else if($4->node->category == CONSTANT_t){
									if($4->pType->type == INTEGER_t){
										fprintf(writefile,"ldc %d\n",$4->node->attribute->constVal->value.integerVal);
									}
									else if($4->pType->type == FLOAT_t){
										fprintf(writefile,"ldc %f\n",$4->node->attribute->constVal->value.floatVal);
									}
									else if($4->pType->type == DOUBLE_t){
										fprintf(writefile,"ldc2_w %lf\n",$4->node->attribute->constVal->value.doubleVal);
									}
									else if($4->pType->type == BOOLEAN_t){
										if($4->node->attribute->constVal->value.booleanVal == __TRUE){
											fprintf(writefile,"iconst_1\n");
										}
										else{
											fprintf(writefile,"iconst_0\n");
										}
									}
								}
								else if($4->node->scope == 0){
									if($4->node->category == FUNCTION_t){
									}
									else if($4->pType->type == INTEGER_t){
										fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$4->node->name);
									}
									else if($4->pType->type == FLOAT_t){
										fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$4->node->name);
									}
									else if($4->pType->type == DOUBLE_t){
										fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$4->node->name);
									}
									else if($4->pType->type == BOOLEAN_t){
										fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,$4->node->name);
									}
								}
								else{
									if($4->pType->type == INTEGER_t){
										fprintf(writefile,"iload %d\n",$4->node->local_number);
									}
									else if($4->pType->type == FLOAT_t){
										fprintf(writefile,"fload %d\n",$4->node->local_number);
									}
									else if($4->pType->type == DOUBLE_t){
										fprintf(writefile,"dload %d\n",$4->node->local_number);
									}
									else if($4->pType->type == BOOLEAN_t){
										fprintf(writefile,"iload %d\n",$4->node->local_number);
									}
								}
								$4->isload = __TRUE;
							}
						}
						else{
							if($4->isload == __FALSE){
								if($4->node == NULL){
									if($4->constvalue->category == INTEGER_t){
										fprintf(writefile,"ldc %d\n",$4->constvalue->value.integerVal);
									}
									else if ($4->constvalue->category == FLOAT_t){
										fprintf(writefile,"ldc %f\n",$4->constvalue->value.floatVal);
									}
									else if ($4->constvalue->category == DOUBLE_t){
										fprintf(writefile,"ldc2_w %lf\n",$4->constvalue->value.doubleVal);
									}
								}
								else if($4->node->category == CONSTANT_t){
									if($4->pType->type == INTEGER_t){
										fprintf(writefile,"ldc %d\n",$4->node->attribute->constVal->value.integerVal);
									}
									else if($4->pType->type == FLOAT_t){
										fprintf(writefile,"ldc %f\n",$4->node->attribute->constVal->value.floatVal);
									}
									else if($4->pType->type == DOUBLE_t){
										fprintf(writefile,"ldc2_w %lf\n",$4->node->attribute->constVal->value.doubleVal);
									}
								}
								else if($4->node->scope == 0){
									if($4->node->category == FUNCTION_t){
									}
									else if($4->pType->type == INTEGER_t){
										fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$4->node->name);
									}
									else if($4->pType->type == FLOAT_t){
										fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$4->node->name);
									}
									else if($4->pType->type == DOUBLE_t){
										fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$4->node->name);
									}
								}
								else{
									if($4->pType->type == INTEGER_t){
										fprintf(writefile,"iload %d\n",$4->node->local_number);
									}
									else if($4->pType->type == FLOAT_t){
										fprintf(writefile,"fload %d\n",$4->node->local_number);
									}
									else if($4->pType->type == DOUBLE_t){
										fprintf(writefile,"dload %d\n",$4->node->local_number);
									}
								}
								$4->isload = __TRUE;
							}
						}
						first_operand = $1->pType->type;
						if(first_operand == INTEGER_t && $4->pType->type == FLOAT_t){
							fprintf(writefile,"fstore %d\n",temp_register);
							fprintf(writefile,"i2f\n");
							fprintf(writefile,"fload %d\n",temp_register);
						}
						else if(first_operand == FLOAT_t && $4->pType->type == INTEGER_t){
							fprintf(writefile,"i2f\n");
						}
						else if(first_operand == INTEGER_t && $4->pType->type == DOUBLE_t){
							fprintf(writefile,"dstore %d\n",temp_register);
							fprintf(writefile,"i2d\n");
							fprintf(writefile,"dload %d\n",temp_register);
						}
						else if(first_operand == DOUBLE_t && $4->pType->type == INTEGER_t){
							fprintf(writefile,"i2d\n");
						}
						else if(first_operand == FLOAT_t && $4->pType->type == DOUBLE_t){
							fprintf(writefile,"dstore %d\n",temp_register);
							fprintf(writefile,"f2d\n");
							fprintf(writefile,"dload %d\n",temp_register);
						}
						else if(first_operand == DOUBLE_t && $4->pType->type == FLOAT_t){
							fprintf(writefile,"f2d\n");
						}
						
						if($1->pType->type == DOUBLE_t || $4->pType->type == DOUBLE_t){
							fprintf(writefile,"dcmpl\n");
						}
						else if($1->pType->type == FLOAT_t || $4->pType->type == FLOAT_t){
							fprintf(writefile,"fcmpl\n");
						}
						else{
							fprintf(writefile,"isub\n");
						}
						
						verifyRelOp( $1, $2, $4 );
						
						if($2 == LT_t){
							fprintf(writefile,"iflt L%d\n",label_count);
						}
						else if($2 == LE_t){
							fprintf(writefile,"ifle L%d\n",label_count);
						}
						else if($2 == NE_t){
							fprintf(writefile,"ifne L%d\n",label_count);
						}
						else if($2 == GE_t){
							fprintf(writefile,"ifge L%d\n",label_count);
						}
						else if($2 == GT_t){
							fprintf(writefile,"ifgt L%d\n",label_count);
						}
						else if($2 == EQ_t){
							fprintf(writefile,"ifeq L%d\n",label_count);
						}
						
						fprintf(writefile,"iconst_0\n");
						fprintf(writefile,"goto L%d\n",label_count+1);
						fprintf(writefile,"L%d:\n",label_count);
						fprintf(writefile,"iconst_1\n");
						fprintf(writefile,"L%d:\n",label_count+1);
						
						label_count += 2;
						
						$$ = $1;
					}
					| arithmetic_expression { $$ = $1; }
					;

relation_operator : LT_OP { $$ = LT_t; }
				  | LE_OP { $$ = LE_t; }
				  | EQ_OP { $$ = EQ_t; }
				  | GE_OP { $$ = GE_t; }
				  | GT_OP { $$ = GT_t; }
				  | NE_OP { $$ = NE_t; }
				  ;

arithmetic_expression : arithmetic_expression add_op 
			{
				if($1->isload == __FALSE){
					if($1->node == NULL){
						if($1->constvalue->category == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$1->constvalue->value.integerVal);
						}
						else if ($1->constvalue->category == FLOAT_t){
							fprintf(writefile,"ldc %f\n",$1->constvalue->value.floatVal);
						}
						else if ($1->constvalue->category == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",$1->constvalue->value.doubleVal);
						}
					}
					else if($1->node->category == CONSTANT_t){
						if($1->pType->type == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$1->node->attribute->constVal->value.integerVal);
						}
						else if($1->pType->type == FLOAT_t){
							fprintf(writefile,"ldc %f\n",$1->node->attribute->constVal->value.floatVal);
						}
						else if($1->pType->type == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",$1->node->attribute->constVal->value.doubleVal);
						}
					}
					else if($1->node->scope == 0){
						if($1->node->category == FUNCTION_t){
						}
						else if($1->pType->type == INTEGER_t){
							fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$1->node->name);
						}
						else if($1->pType->type == FLOAT_t){
							fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$1->node->name);
						}
						else if($1->pType->type == DOUBLE_t){
							fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$1->node->name);
						}
					}
					else{
						if($1->pType->type == INTEGER_t){
							fprintf(writefile,"iload %d\n",$1->node->local_number);
						}
						else if($1->pType->type == FLOAT_t){
							fprintf(writefile,"fload %d\n",$1->node->local_number);
						}
						else if($1->pType->type == DOUBLE_t){
							fprintf(writefile,"dload %d\n",$1->node->local_number);
						}
					}
					$1->isload = __TRUE;
				}
			}
			term
			{
				first_operand = $1->pType->type;
				verifyArithmeticOp( $1, $2, $4 );
				if($4->isload == __FALSE){
					if($4->node == NULL){
						if($4->constvalue->category == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$4->constvalue->value.integerVal);
						}
						else if ($4->constvalue->category == FLOAT_t){
							fprintf(writefile,"ldc %f\n",$4->constvalue->value.floatVal);
						}
						else if ($4->constvalue->category == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",$4->constvalue->value.doubleVal);
						}
					}
					else if($4->node->category == CONSTANT_t){
						if($4->pType->type == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$4->node->attribute->constVal->value.integerVal);
						}
						else if($4->pType->type == FLOAT_t){
							fprintf(writefile,"ldc %f\n",$4->node->attribute->constVal->value.floatVal);
						}
						else if($4->pType->type == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",$4->node->attribute->constVal->value.doubleVal);
						}
						else if($4->pType->type == BOOLEAN_t){
							if($4->node->attribute->constVal->value.booleanVal == __TRUE){
								fprintf(writefile,"iconst_1\n");
							}
							else{
								fprintf(writefile,"iconst_0\n");
							}
						}
					}
					else if($4->node->scope == 0){
						if($4->node->category == FUNCTION_t){
						}
						else if($4->pType->type == INTEGER_t){
							fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$4->node->name);
						}
						else if($4->pType->type == FLOAT_t){
							fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$4->node->name);
						}
						else if($4->pType->type == DOUBLE_t){
							fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$4->node->name);
						}
					}
					else{
						if($4->pType->type == INTEGER_t){
							fprintf(writefile,"iload %d\n",$4->node->local_number);
						}
						else if($4->pType->type == FLOAT_t){
							fprintf(writefile,"fload %d\n",$4->node->local_number);
						}
						else if($4->pType->type == DOUBLE_t){
							fprintf(writefile,"dload %d\n",$4->node->local_number);
						}
					}
					$4->isload = __TRUE;
				}
				
				if(first_operand == INTEGER_t && $4->pType->type == FLOAT_t){
					fprintf(writefile,"fstore %d\n",temp_register);
					fprintf(writefile,"i2f\n");
					fprintf(writefile,"fload %d\n",temp_register);
				}
				else if(first_operand == FLOAT_t && $4->pType->type == INTEGER_t){
					fprintf(writefile,"i2f\n");
				}
				else if(first_operand == INTEGER_t && $4->pType->type == DOUBLE_t){
					fprintf(writefile,"dstore %d\n",temp_register);
					fprintf(writefile,"i2d\n");
					fprintf(writefile,"dload %d\n",temp_register);
				}
				else if(first_operand == DOUBLE_t && $4->pType->type == INTEGER_t){
					fprintf(writefile,"i2d\n");
				}
				else if(first_operand == FLOAT_t && $4->pType->type == DOUBLE_t){
					fprintf(writefile,"dstore %d\n",temp_register);
					fprintf(writefile,"f2d\n");
					fprintf(writefile,"dload %d\n",temp_register);
				}
				else if(first_operand == DOUBLE_t && $4->pType->type == FLOAT_t){
					fprintf(writefile,"f2d\n");
				}
				
				if($2 == ADD_t){
					if($1->pType->type == INTEGER_t){
						fprintf(writefile,"iadd\n");
					}
					else if($1->pType->type == FLOAT_t){
						fprintf(writefile,"fadd\n");
					}
					else if($1->pType->type == DOUBLE_t){
						fprintf(writefile,"dadd\n");
					}
				}
				else{
					if($1->pType->type == INTEGER_t){
						fprintf(writefile,"isub\n");
					}
					else if($1->pType->type == FLOAT_t){
						fprintf(writefile,"fsub\n");
					}
					else if($1->pType->type == DOUBLE_t){
						fprintf(writefile,"dsub\n");
					}
				}
				
				$$ = $1;
			}
           | relation_expression { $$ = $1; }
		   | term { $$ = $1; }
		   ;

add_op	: ADD_OP { $$ = ADD_t; }
		| SUB_OP { $$ = SUB_t; }
		;
		   
term : term mul_op 
		{
			if($2 == MOD_t){
				if($1->isload == __FALSE){
					if($1->node == NULL){
						if($1->constvalue->category == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$1->constvalue->value.integerVal);
						}
					}
					else if($1->node->category == CONSTANT_t){
						if($1->pType->type == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$1->node->attribute->constVal->value.integerVal);
						}
					}
					else if($1->node->scope == 0){
						if($1->node->category == FUNCTION_t){
						}
						else if($1->pType->type == INTEGER_t){
							fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$1->node->name);
						}
					}
					else{
						if($1->pType->type == INTEGER_t){
							fprintf(writefile,"iload %d\n",$1->node->local_number);
						}
					}
					$1->isload = __TRUE;
				}
			}
			else{
				if($1->isload == __FALSE){
					if($1->node == NULL){
						if($1->constvalue->category == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$1->constvalue->value.integerVal);
						}
						else if ($1->constvalue->category == FLOAT_t){
							fprintf(writefile,"ldc %f\n",$1->constvalue->value.floatVal);
						}
						else if ($1->constvalue->category == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",$1->constvalue->value.doubleVal);
						}
					}
					else if($1->node->category == CONSTANT_t){
						if($1->pType->type == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$1->node->attribute->constVal->value.integerVal);
						}
						else if($1->pType->type == FLOAT_t){
							fprintf(writefile,"ldc %f\n",$1->node->attribute->constVal->value.floatVal);
						}
						else if($1->pType->type == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",$1->node->attribute->constVal->value.doubleVal);
						}
					}
					else if($1->node->scope == 0){
						if($1->node->category == FUNCTION_t){
						}
						else if($1->pType->type == INTEGER_t){
							fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$1->node->name);
						}
						else if($1->pType->type == FLOAT_t){
							fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$1->node->name);
						}
						else if($1->pType->type == DOUBLE_t){
							fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$1->node->name);
						}
					}
					else{
						if($1->pType->type == INTEGER_t){
							fprintf(writefile,"iload %d\n",$1->node->local_number);
						}
						else if($1->pType->type == FLOAT_t){
							fprintf(writefile,"fload %d\n",$1->node->local_number);
						}
						else if($1->pType->type == DOUBLE_t){
							fprintf(writefile,"dload %d\n",$1->node->local_number);
						}
					}
					$1->isload = __TRUE;
				}
			}
		}
		factor
		{
			if( $2 == MOD_t ) {
				verifyModOp( $1, $4 );
				
				if($4->isload == __FALSE){
					if($4->node == NULL){
						if($4->constvalue->category == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$4->constvalue->value.integerVal);
						}
					}
					else if($4->node->category == CONSTANT_t){
						if($4->pType->type == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$4->node->attribute->constVal->value.integerVal);
						}
					}
					else if($4->node->scope == 0){
						if($4->node->category == FUNCTION_t){
						}
						else if($4->pType->type == INTEGER_t){
							fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$4->node->name);
						}
					}
					else{
						if($4->pType->type == INTEGER_t){
							fprintf(writefile,"iload %d\n",$4->node->local_number);
						}
					}
					$4->isload = __TRUE;
				}
				if($1->pType->type == INTEGER_t){
					fprintf(writefile,"irem\n");
				}
			}
			else {
				first_operand = $1->pType->type;
				verifyArithmeticOp( $1, $2, $4 );
				if($4->isload == __FALSE){
					if($4->node == NULL){
						if($4->constvalue->category == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$4->constvalue->value.integerVal);
						}
						else if ($4->constvalue->category == FLOAT_t){
							fprintf(writefile,"ldc %f\n",$4->constvalue->value.floatVal);
						}
						else if ($4->constvalue->category == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",$4->constvalue->value.doubleVal);
						}
					}
					else if($4->node->category == CONSTANT_t){
						if($4->pType->type == INTEGER_t){
							fprintf(writefile,"ldc %d\n",$4->node->attribute->constVal->value.integerVal);
						}
						else if($4->pType->type == FLOAT_t){
							fprintf(writefile,"ldc %f\n",$4->node->attribute->constVal->value.floatVal);
						}
						else if($4->pType->type == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",$4->node->attribute->constVal->value.doubleVal);
						}
					}
					else if($4->node->scope == 0){
						if($4->node->category == FUNCTION_t){
						}
						else if($4->pType->type == INTEGER_t){
							fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$4->node->name);
						}
						else if($4->pType->type == FLOAT_t){
							fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$4->node->name);
						}
						else if($4->pType->type == DOUBLE_t){
							fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$4->node->name);
						}
					}
					else{
						if($4->pType->type == INTEGER_t){
							fprintf(writefile,"iload %d\n",$4->node->local_number);
						}
						else if($4->pType->type == FLOAT_t){
							fprintf(writefile,"fload %d\n",$4->node->local_number);
						}
						else if($4->pType->type == DOUBLE_t){
							fprintf(writefile,"dload %d\n",$4->node->local_number);
						}
					}
					$4->isload = __TRUE;
				}
				
				if(first_operand == INTEGER_t && $4->pType->type == FLOAT_t){
					fprintf(writefile,"fstore %d\n",temp_register);
					fprintf(writefile,"i2f\n");
					fprintf(writefile,"fload %d\n",temp_register);
				}
				else if(first_operand == FLOAT_t && $4->pType->type == INTEGER_t){
					fprintf(writefile,"i2f\n");
				}
				else if(first_operand == INTEGER_t && $4->pType->type == DOUBLE_t){
					fprintf(writefile,"dstore %d\n",temp_register);
					fprintf(writefile,"i2d\n");
					fprintf(writefile,"dload %d\n",temp_register);
				}
				else if(first_operand == DOUBLE_t && $4->pType->type == INTEGER_t){
					fprintf(writefile,"i2d\n");
				}
				else if(first_operand == FLOAT_t && $4->pType->type == DOUBLE_t){
					fprintf(writefile,"dstore %d\n",temp_register);
					fprintf(writefile,"f2d\n");
					fprintf(writefile,"dload %d\n",temp_register);
				}
				else if(first_operand == DOUBLE_t && $4->pType->type == FLOAT_t){
					fprintf(writefile,"f2d\n");
				}
				
				if($2 == MUL_t){
					if($1->pType->type == INTEGER_t){
						fprintf(writefile,"imul\n");
					}
					else if($1->pType->type == FLOAT_t){
						fprintf(writefile,"fmul\n");
					}
					else if($1->pType->type == DOUBLE_t){
						fprintf(writefile,"dmul\n");
					}
				}
				else{
					if($1->pType->type == INTEGER_t){
						fprintf(writefile,"idiv\n");
					}
					else if($1->pType->type == FLOAT_t){
						fprintf(writefile,"fdiv\n");
					}
					else if($1->pType->type == DOUBLE_t){
						fprintf(writefile,"ddiv\n");
					}
				}
			}
			$$ = $1;
		}
     | factor { $$ = $1; }
	 ;

mul_op 	: MUL_OP { $$ = MUL_t; }
		| DIV_OP { $$ = DIV_t; }
		| MOD_OP { $$ = MOD_t; }
		;
		
factor : variable_reference
		{
			verifyExistence( symbolTable, $1, scope, __FALSE );
			$$ = $1;
			$$->beginningOp = NONE_t;
		}
	   | SUB_OP variable_reference
		{
			if( verifyExistence( symbolTable, $2, scope, __FALSE ) == __TRUE ){
				verifyUnaryMinus( $2 );
				
				if($2->node->category == CONSTANT_t){
					if($2->pType->type == INTEGER_t){
						fprintf(writefile,"ldc %d\n",$2->node->attribute->constVal->value.integerVal);
					}
					else if($2->pType->type == FLOAT_t){
						fprintf(writefile,"ldc %f\n",$2->node->attribute->constVal->value.floatVal);
					}
					else if($2->pType->type == DOUBLE_t){
						fprintf(writefile,"ldc2_w %lf\n",$2->node->attribute->constVal->value.doubleVal);
					}
				}
				else if($2->node->scope == 0){
					if($2->node->category == FUNCTION_t){
					}
					else if($2->pType->type == INTEGER_t){
						fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$2->node->name);
					}
					else if($2->pType->type == FLOAT_t){
						fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$2->node->name);
					}
					else if($2->pType->type == DOUBLE_t){
						fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$2->node->name);
					}
				}
				else{
					if($2->pType->type == INTEGER_t){
						fprintf(writefile,"iload %d\n",$2->node->local_number);
					}
					else if($2->pType->type == FLOAT_t){
						fprintf(writefile,"fload %d\n",$2->node->local_number);
					}
					else if($2->pType->type == DOUBLE_t){
						fprintf(writefile,"dload %d\n",$2->node->local_number);
					}
				}
				$2->isload = __TRUE;
				if($2->pType->type == INTEGER_t){
					fprintf(writefile,"ineg\n");
				}
				else if($2->pType->type == FLOAT_t){
					fprintf(writefile,"fneg\n");
				}
				else if($2->pType->type == DOUBLE_t){
					fprintf(writefile,"dneg\n");
				}
			}
			$$ = $2;
			$$->beginningOp = SUB_t;
		}		
	   | L_PAREN logical_expression R_PAREN
		{
			$2->beginningOp = NONE_t;
			$$ = $2; 
			if($2->isload == __FALSE){
				if($2->node == NULL){
					if($2->constvalue->category == INTEGER_t){
						fprintf(writefile,"ldc %d\n",$2->constvalue->value.integerVal);
					}
					else if ($2->constvalue->category == FLOAT_t){
						fprintf(writefile,"ldc %f\n",$2->constvalue->value.floatVal);
					}
					else if ($2->constvalue->category == DOUBLE_t){
						fprintf(writefile,"ldc2_w %lf\n",$2->constvalue->value.doubleVal);
					}
				}
				else if($2->node->category == CONSTANT_t){
					if($2->pType->type == INTEGER_t){
						fprintf(writefile,"ldc %d\n",$2->node->attribute->constVal->value.integerVal);
					}
					else if($2->pType->type == FLOAT_t){
						fprintf(writefile,"ldc %f\n",$2->node->attribute->constVal->value.floatVal);
					}
					else if($2->pType->type == DOUBLE_t){
						fprintf(writefile,"ldc2_w %lf\n",$2->node->attribute->constVal->value.doubleVal);
					}
				}
				else if($2->node->scope == 0){
					if($2->node->category == FUNCTION_t){
					}
					else if($2->pType->type == INTEGER_t){
						fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$2->node->name);
					}
					else if($2->pType->type == FLOAT_t){
						fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$2->node->name);
					}
					else if($2->pType->type == DOUBLE_t){
						fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$2->node->name);
					}
				}
				else{
					if($2->pType->type == INTEGER_t){
						fprintf(writefile,"iload %d\n",$2->node->local_number);
					}
					else if($2->pType->type == FLOAT_t){
						fprintf(writefile,"fload %d\n",$2->node->local_number);
					}
					else if($2->pType->type == DOUBLE_t){
						fprintf(writefile,"dload %d\n",$2->node->local_number);
					}
				}
				$2->isload = __TRUE;
			}
		}
	   | SUB_OP L_PAREN logical_expression R_PAREN
		{
			verifyUnaryMinus( $3 );
			if($3->isload == __FALSE){
				if($3->node == NULL){
					if($3->constvalue->category == INTEGER_t){
						fprintf(writefile,"ldc %d\n",$3->constvalue->value.integerVal);
					}
					else if($3->constvalue->category == FLOAT_t){
						fprintf(writefile,"ldc %f\n",$3->constvalue->value.floatVal);
					}
					else if($3->constvalue->category == DOUBLE_t){
						fprintf(writefile,"ldc2_w %lf\n",$3->constvalue->value.doubleVal);
					}
				}
				else if($3->node->category == CONSTANT_t){
					if($3->pType->type == INTEGER_t){
						fprintf(writefile,"ldc %d\n",$3->node->attribute->constVal->value.integerVal);
					}
					else if($3->pType->type == FLOAT_t){
						fprintf(writefile,"ldc %f\n",$3->node->attribute->constVal->value.floatVal);
					}
					else if($3->pType->type == DOUBLE_t){
						fprintf(writefile,"ldc2_w %lf\n",$3->node->attribute->constVal->value.doubleVal);
					}
				}
				else if($3->node->scope == 0){
					if($3->node->category == FUNCTION_t){
					}
					else if($3->pType->type == INTEGER_t){
						fprintf(writefile,"getstatic %s/%s I\n",frontfileName,$3->node->name);
					}
					else if($3->pType->type == FLOAT_t){
						fprintf(writefile,"getstatic %s/%s F\n",frontfileName,$3->node->name);
					}
					else if($3->pType->type == DOUBLE_t){
						fprintf(writefile,"getstatic %s/%s D\n",frontfileName,$3->node->name);
					}
				}
				else{
					if($3->pType->type == INTEGER_t){
						fprintf(writefile,"iload %d\n",$3->node->local_number);
					}
					else if($3->pType->type == FLOAT_t){
						fprintf(writefile,"fload %d\n",$3->node->local_number);
					}
					else if($3->pType->type == DOUBLE_t){
						fprintf(writefile,"dload %d\n",$3->node->local_number);
					}
				}
				$3->isload = __TRUE;
			}
			
			if($3->pType->type == INTEGER_t){
				fprintf(writefile,"ineg\n");
			}
			else if($3->pType->type == FLOAT_t){
				fprintf(writefile,"fneg\n");
			}
			else if($3->pType->type == DOUBLE_t){
				fprintf(writefile,"dneg\n");
			}
			
			$$ = $3;
			$$->beginningOp = SUB_t;
		}
	   | ID L_PAREN logical_expression_list R_PAREN
		{
			$$ = verifyFuncInvoke( $1, $3, symbolTable, scope );
			$$->beginningOp = NONE_t;
			struct expr_sem *temp1 = $3;
			struct PTypeList *temp2 = $$->node->attribute->formalParam->params;
			while(temp1 != NULL && temp2 != NULL){
				if(temp1->isload == __FALSE){
					if(temp1->node == NULL){
						if(temp1->constvalue->category == INTEGER_t){
							fprintf(writefile,"ldc %d\n",temp1->constvalue->value.integerVal);
						}
						else if (temp1->constvalue->category == FLOAT_t){
							fprintf(writefile,"ldc %f\n",temp1->constvalue->value.floatVal);
						}
						else if (temp1->constvalue->category == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",temp1->constvalue->value.doubleVal);
						}
						else if (temp1->constvalue->category == BOOLEAN_t){
							if(temp1->constvalue->value.booleanVal == __TRUE){
								fprintf(writefile,"iconst_1\n");
							}
							else{
								fprintf(writefile,"iconst_0\n");
							}
						}
					}
					else if(temp1->node->category == CONSTANT_t){
						if(temp1->pType->type == INTEGER_t){
							fprintf(writefile,"ldc %d\n",temp1->node->attribute->constVal->value.integerVal);
						}
						else if(temp1->pType->type == FLOAT_t){
							fprintf(writefile,"ldc %f\n",temp1->node->attribute->constVal->value.floatVal);
						}
						else if(temp1->pType->type == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",temp1->node->attribute->constVal->value.doubleVal);
						}
						else if(temp1->pType->type == BOOLEAN_t){
							if(temp1->node->attribute->constVal->value.booleanVal == __TRUE){
								fprintf(writefile,"iconst_1\n");
							}
							else{
								fprintf(writefile,"iconst_0\n");
							}
						}
					}
					else if(temp1->node->scope == 0){
						if(temp1->node->category == FUNCTION_t){
						}
						else if(temp1->pType->type == INTEGER_t){
							fprintf(writefile,"getstatic %s/%s I\n",frontfileName,temp1->node->name);
						}
						else if(temp1->pType->type == FLOAT_t){
							fprintf(writefile,"getstatic %s/%s F\n",frontfileName,temp1->node->name);
						}
						else if(temp1->pType->type == DOUBLE_t){
							fprintf(writefile,"getstatic %s/%s D\n",frontfileName,temp1->node->name);
						}
						else if(temp1->pType->type == BOOLEAN_t){
							fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,temp1->node->name);
						}
					}
					else{
						if(temp1->pType->type == INTEGER_t){
							fprintf(writefile,"iload %d\n",temp1->node->local_number);
						}
						else if(temp1->pType->type == FLOAT_t){
							fprintf(writefile,"fload %d\n",temp1->node->local_number);
						}
						else if(temp1->pType->type == DOUBLE_t){
							fprintf(writefile,"dload %d\n",temp1->node->local_number);
						}
						else if(temp1->pType->type == BOOLEAN_t){
							fprintf(writefile,"iload %d\n",temp1->node->local_number);
						}
					}
					temp1->isload = __TRUE;
				}
				
				if(temp2->value->type == FLOAT_t && temp1->pType->type == INTEGER_t){
					fprintf(writefile,"i2f\n");
				}
				else if(temp2->value->type == DOUBLE_t && temp1->pType->type == INTEGER_t){
					fprintf(writefile,"i2d\n");
				}
				else if(temp2->value->type == DOUBLE_t && temp1->pType->type == FLOAT_t){
					fprintf(writefile,"f2d\n");
				}
				
				temp1 = temp1->next;
				temp2 = temp2->next;
			}
			fprintf(writefile,"invokestatic %s/%s(",frontfileName,$1);
			struct PTypeList *temp = $$->node->attribute->formalParam->params;
			while(temp != NULL){
				if(temp->value->type == INTEGER_t){
					fprintf(writefile,"I");
				}
				else if(temp->value->type == FLOAT_t){
					fprintf(writefile,"F");
				}
				else if(temp->value->type == DOUBLE_t){
					fprintf(writefile,"D");
				}
				else if(temp->value->type == BOOLEAN_t){
					fprintf(writefile,"Z");
				}
				temp = temp->next;
			}
			if($$->pType->type == INTEGER_t){
				fprintf(writefile,")I\n");
			}
			else if($$->pType->type == FLOAT_t){
				fprintf(writefile,")F\n");
			}
			else if($$->pType->type == DOUBLE_t){
				fprintf(writefile,")D\n");
			}
			else if($$->pType->type == BOOLEAN_t){
				fprintf(writefile,")Z\n");
			}
			else if($$->pType->type == VOID_t){
				fprintf(writefile,")V\n");
			}
		}
	   | SUB_OP ID L_PAREN logical_expression_list R_PAREN
	    {
			$$ = verifyFuncInvoke( $2, $4, symbolTable, scope );
			$$->beginningOp = SUB_t;
			struct expr_sem *temp1 = $4;
			struct PTypeList *temp2 = $$->node->attribute->formalParam->params;
			while(temp1 != NULL && temp2 != NULL){
				if(temp1->isload == __FALSE){
					if(temp1->node == NULL){
						if(temp1->constvalue->category == INTEGER_t){
							fprintf(writefile,"ldc %d\n",temp1->constvalue->value.integerVal);
						}
						else if (temp1->constvalue->category == FLOAT_t){
							fprintf(writefile,"ldc %f\n",temp1->constvalue->value.floatVal);
						}
						else if (temp1->constvalue->category == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",temp1->constvalue->value.doubleVal);
						}
						else if (temp1->constvalue->category == BOOLEAN_t){
							if(temp1->constvalue->value.booleanVal == __TRUE){
								fprintf(writefile,"iconst_1\n");
							}
							else{
								fprintf(writefile,"iconst_0\n");
							}
						}
					}
					else if(temp1->node->category == CONSTANT_t){
						if(temp1->pType->type == INTEGER_t){
							fprintf(writefile,"ldc %d\n",temp1->node->attribute->constVal->value.integerVal);
						}
						else if(temp1->pType->type == FLOAT_t){
							fprintf(writefile,"ldc %f\n",temp1->node->attribute->constVal->value.floatVal);
						}
						else if(temp1->pType->type == DOUBLE_t){
							fprintf(writefile,"ldc2_w %lf\n",temp1->node->attribute->constVal->value.doubleVal);
						}
						else if(temp1->pType->type == BOOLEAN_t){
							if(temp1->node->attribute->constVal->value.booleanVal == __TRUE){
								fprintf(writefile,"iconst_1\n");
							}
							else{
								fprintf(writefile,"iconst_0\n");
							}
						}
					}
					else if(temp1->node->scope == 0){
						if(temp1->node->category == FUNCTION_t){
						}
						else if(temp1->pType->type == INTEGER_t){
							fprintf(writefile,"getstatic %s/%s I\n",frontfileName,temp1->node->name);
						}
						else if(temp1->pType->type == FLOAT_t){
							fprintf(writefile,"getstatic %s/%s F\n",frontfileName,temp1->node->name);
						}
						else if(temp1->pType->type == DOUBLE_t){
							fprintf(writefile,"getstatic %s/%s D\n",frontfileName,temp1->node->name);
						}
						else if(temp1->pType->type == BOOLEAN_t){
							fprintf(writefile,"getstatic %s/%s Z\n",frontfileName,temp1->node->name);
						}
					}
					else{
						if(temp1->pType->type == INTEGER_t){
							fprintf(writefile,"iload %d\n",temp1->node->local_number);
						}
						else if(temp1->pType->type == FLOAT_t){
							fprintf(writefile,"fload %d\n",temp1->node->local_number);
						}
						else if(temp1->pType->type == DOUBLE_t){
							fprintf(writefile,"dload %d\n",temp1->node->local_number);
						}
						else if(temp1->pType->type == BOOLEAN_t){
							fprintf(writefile,"iload %d\n",temp1->node->local_number);
						}
					}
					temp1->isload = __TRUE;
				}
				
				if(temp2->value->type == FLOAT_t && temp1->pType->type == INTEGER_t){
					fprintf(writefile,"i2f\n");
				}
				else if(temp2->value->type == DOUBLE_t && temp1->pType->type == INTEGER_t){
					fprintf(writefile,"i2d\n");
				}
				else if(temp2->value->type == DOUBLE_t && temp1->pType->type == FLOAT_t){
					fprintf(writefile,"f2d\n");
				}
				
				temp1 = temp1->next;
				temp2 = temp2->next;
			}
			fprintf(writefile,"invokestatic %s/%s(",frontfileName,$2);
			struct PTypeList *temp = $$->node->attribute->formalParam->params;
			while(temp != NULL){
				if(temp->value->type == INTEGER_t){
					fprintf(writefile,"I");
				}
				else if(temp->value->type == FLOAT_t){
					fprintf(writefile,"F");
				}
				else if(temp->value->type == DOUBLE_t){
					fprintf(writefile,"D");
				}
				else if(temp->value->type == BOOLEAN_t){
					fprintf(writefile,"Z");
				}
				temp = temp->next;
			}
			if($$->pType->type == INTEGER_t){
				fprintf(writefile,")I\n");
				fprintf(writefile,"ineg\n");
			}
			else if($$->pType->type == FLOAT_t){
				fprintf(writefile,")F\n");
				fprintf(writefile,"fneg\n");
			}
			else if($$->pType->type == DOUBLE_t){
				fprintf(writefile,")D\n");
				fprintf(writefile,"dneg\n");
			}
		}
	   | ID L_PAREN R_PAREN
		{
			$$ = verifyFuncInvoke( $1, 0, symbolTable, scope );
			$$->beginningOp = NONE_t;
			if($$->pType->type == VOID_t){
				fprintf(writefile,"invokestatic %s/%s()V\n",frontfileName,$1);
			}
			else if($$->pType->type == INTEGER_t){
				fprintf(writefile,"invokestatic %s/%s()I\n",frontfileName,$1);
			}
			else if($$->pType->type == FLOAT_t){
				fprintf(writefile,"invokestatic %s/%s()F\n",frontfileName,$1);
			}
			else if($$->pType->type == DOUBLE_t){
				fprintf(writefile,"invokestatic %s/%s()D\n",frontfileName,$1);
			}
			else if($$->pType->type == BOOLEAN_t){
				fprintf(writefile,"invokestatic %s/%s()Z\n",frontfileName,$1);
			}
		}
	   | SUB_OP ID L_PAREN R_PAREN
		{
			$$ = verifyFuncInvoke( $2, 0, symbolTable, scope );
			$$->beginningOp = SUB_OP;
			if($$->pType->type == INTEGER_t){
				fprintf(writefile,"invokestatic %s/%s()I\n",frontfileName,$2);
				fprintf(writefile,"ineg\n");
			}
			else if($$->pType->type == FLOAT_t){
				fprintf(writefile,"invokestatic %s/%s()F\n",frontfileName,$2);
				fprintf(writefile,"fneg\n");
			}
			else if($$->pType->type == DOUBLE_t){
				fprintf(writefile,"invokestatic %s/%s()D\n",frontfileName,$2);
				fprintf(writefile,"dneg\n");
			}
		}
	   | literal_const
	    {
			  $$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  $$->isDeref = __TRUE;
			  $$->varRef = 0;
			  $$->pType = createPType( $1->category );
			  $$->next = 0;
			  $$->constvalue = $1;
			  $$->node = NULL;
			  $$->isload = __FALSE;
			  if( $1->hasMinus == __TRUE ) {
			  	$$->beginningOp = SUB_t;
			  }
			  else {
				$$->beginningOp = NONE_t;
			  }
		}
	   ;

logical_expression_list : logical_expression_list COMMA logical_expression
						{
			  				struct expr_sem *exprPtr;
			  				for( exprPtr=$1 ; (exprPtr->next)!=0 ; exprPtr=(exprPtr->next) );
			  				exprPtr->next = $3;
			  				$$ = $1;	
						}
						| logical_expression 
						{ 
							$$ = $1; 
						}
						;

		  


scalar_type : INT { $$ = createPType( INTEGER_t ); var_decl_type = INTEGER_t;}
			| DOUBLE { $$ = createPType( DOUBLE_t ); var_decl_type = DOUBLE_t;}
			| STRING { $$ = createPType( STRING_t ); var_decl_type = STRING_t;}
			| BOOL { $$ = createPType( BOOLEAN_t ); var_decl_type = BOOLEAN_t;}
			| FLOAT { $$ = createPType( FLOAT_t ); var_decl_type = FLOAT_t;}
			;
 
literal_const : INT_CONST
				{
					int tmp = $1;
					$$ = createConstAttr( INTEGER_t, &tmp );
				}
			  | SUB_OP INT_CONST
				{
					int tmp = -$2;
					$$ = createConstAttr( INTEGER_t, &tmp );
				}
			  | FLOAT_CONST
				{
					float tmp = $1;
					$$ = createConstAttr( FLOAT_t, &tmp );
				}
			  | SUB_OP FLOAT_CONST
			    {
					float tmp = -$2;
					$$ = createConstAttr( FLOAT_t, &tmp );
				}
			  | SCIENTIFIC
				{
					double tmp = $1;
					$$ = createConstAttr( DOUBLE_t, &tmp );
				}
			  | SUB_OP SCIENTIFIC
				{
					double tmp = -$2;
					$$ = createConstAttr( DOUBLE_t, &tmp );
				}
			  | STR_CONST
				{
					$$ = createConstAttr( STRING_t, $1 );
				}
			  | TRUE
				{
					SEMTYPE tmp = __TRUE;
					$$ = createConstAttr( BOOLEAN_t, &tmp );
				}
			  | FALSE
				{
					SEMTYPE tmp = __FALSE;
					$$ = createConstAttr( BOOLEAN_t, &tmp );
				}
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
}


