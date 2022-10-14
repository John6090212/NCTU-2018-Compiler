%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include"datatype.h"
#include"symtable.h"

extern int linenum;
extern FILE	*yyin;
extern char	*yytext;
extern char buf[256];
extern int Opt_SymTable;//declared in lex.l
int scope = 0;//default is 0(global)
struct SymTableList *symbolTableList;//create and initialize in main.c
struct ExtType *funcReturnType;
struct FuncDeclNode *func_decl_table = NULL; // use to check function declaration
int break_allow = 0;
int continue_allow = 0;
bool has_return = false;
bool in_func_def = false;
BTYPE func_def_type;
bool parameter_has_fault = false;
bool array_decl_has_fault = false;

%}
%union{
	int 			intVal;
	float 			floatVal;
	double 			doubleVal;
	char			*stringVal;
	char			*idName;
	struct ExtType 		*extType;
	struct Variable		*variable;
	struct VariableList	*variableList;
	struct ArrayDimNode	*arrayDimNode;
	//struct ConstAttr	*constAttr;
	struct FuncAttrNode	*funcAttrNode;
	//struct FuncAttr		*funcAttr;
	struct Attribute	*attribute;
	struct SymTableNode	*symTableNode;
	//struct SymTable		*symTable;
	BTYPE			bType;
	REL_OP			rel_op;
};

%token <idName> ID
%token <intVal> INT_CONST
%token <floatVal> FLOAT_CONST
%token <doubleVal> SCIENTIFIC
%token <stringVal> STR_CONST

%type <variable> array_decl
%type <variableList> identifier_list
%type <arrayDimNode> dim
%type <funcAttrNode> parameter_list
%type <attribute> literal_const 
%type <symTableNode> const_list
%type <bType> scalar_type
%type <extType> logical_expression
%type <extType> logical_term
%type <extType> logical_factor
%type <extType> relation_expression
%type <extType> arithmetic_expression
%type <extType> term
%type <extType> factor
%type <symTableNode> variable_reference
%type <arrayDimNode> dimension
%type <rel_op> relation_operator
%type <variableList> literal_list
%type <variableList> initial_array
%type <symTableNode> array_list
%type <variableList> logical_expression_list

%token  LE_OP
%token	NE_OP
%token	GE_OP
%token	EQ_OP
%token	AND_OP
%token	OR_OP

%token	READ
%token	BOOLEAN
%token	WHILE
%token	DO
%token	IF
%token	ELSE
%token	TRUE
%token	FALSE
%token	FOR
%token	INT
%token	PRINT
%token	BOOL
%token	VOID
%token	FLOAT
%token	DOUBLE
%token	STRING
%token	CONTINUE
%token	BREAK
%token	RETURN
%token  CONST

%token	L_PAREN
%token	R_PAREN
%token	COMMA
%token	SEMICOLON
%token	ML_BRACE
%token	MR_BRACE
%token	L_BRACE
%token	R_BRACE
%token	ADD_OP
%token	SUB_OP
%token	MUL_OP
%token	DIV_OP
%token	MOD_OP
%token	ASSIGN_OP
%token	LT_OP
%token	GT_OP
%token	NOT_OP

/*	Program 
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

program :  decl_list funct_def decl_and_def_list
	{
		checkFuncDeclList(func_decl_table,linenum);
	
		if(Opt_SymTable == 1)
			printSymTable(symbolTableList->global);
		deleteLastSymTable(symbolTableList);
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
				funcReturnType = createExtType($1,0,0,NULL,NULL,0,false);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				if(node==NULL)//no declaration yet
				{
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
					insertTableNode(symbolTableList->global,newNode);
				}
				else{
					struct FuncDeclNode *node2;
					node2 = searchFuncDeclList(func_decl_table,$2);
					if(node2 == NULL){
						printf("##########Error at Line #%d: Function has already been defined.##########\n",linenum);
					}
					else{
						if(node2->has_defined){
							printf("##########Error at Line #%d: Function has already been defined.##########\n",linenum);
						}
						if(node2->type->baseType != funcReturnType->baseType || node2->attr != NULL){
							printf("##########Error at Line #%d: Function definition doesn't match declaration.##########\n",linenum);
							node2->has_defined = false;
						}	
						else{
							node2->has_defined = true;
						}
					}
				}
				func_def_type = $1;
				in_func_def = true;
				has_return = false;
				
				free($2);
				
			} compound_statement
			{
				if(has_return == false){
					printf("##########Error at Line #%d: Function definition should have at least one return statement.##########\n",linenum);
				}
				in_func_def = false;
				parameter_has_fault = false;
			}
		  | scalar_type ID L_PAREN parameter_list R_PAREN 
		{
				funcReturnType = createExtType($1,0,0,NULL,NULL,0,false);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				struct Attribute *attr = createFunctionAttribute($4);
				if(node==NULL)//no declaration yet
				{
					if(parameter_has_fault == false){
						struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
						insertTableNode(symbolTableList->global,newNode);
					}
				}
				else{
					
					struct FuncDeclNode *node2;
					node2 = searchFuncDeclList(func_decl_table,$2);
					if(node2 == NULL){
						printf("##########Error at Line #%d: Function has already been defined.##########\n",linenum);
					}
					else{
						if(node2->has_defined){
							printf("##########Error at Line #%d: Function has already been defined.##########\n",linenum);
						}
						if(parameter_has_fault){
							printf("##########Error at Line #%d: Function definition is invalid.##########\n",linenum);
							node2->has_defined = false;
						}
						else if(node2->type->baseType != funcReturnType->baseType || node2->attr == NULL){
							printf("##########Error at Line #%d: Function definition doesn't match declaration.##########\n",linenum);
							node2->has_defined = false;
						}
						else if(node2->attr->funcParam->paramNum != attr->funcParam->paramNum){
							printf("##########Error at Line #%d: Function definition doesn't match declaration.##########\n",linenum);
							node2->has_defined = false;
						} 
						else if(!compareFuncAttrNode(node2->attr->funcParam->head,attr->funcParam->head)){
							printf("##########Error at Line #%d: Function definition doesn't match declaration.##########\n",linenum);
							node2->has_defined = false;
						} 
						else{
							node2->has_defined = true;
						}
					}
				}
		}
		L_BRACE 
			{//enter a new scope
				++scope;
				AddSymTable(symbolTableList);
				//add parameters
				struct FuncAttrNode *attrNode = $4;
				while(attrNode!=NULL)
				{
					struct SymTableNode *newNode = createParameterNode(attrNode->name,scope,attrNode->value);
					insertTableNode(symbolTableList->tail,newNode);
					attrNode = attrNode->next;
				}
				func_def_type = $1;
				in_func_def = true;
				has_return = false;
			}
			var_const_stmt_list R_BRACE
			{	
				if(Opt_SymTable == 1)
					printSymTable(symbolTableList->tail);
				deleteLastSymTable(symbolTableList);
				--scope;
				free($2);
				if(has_return == false){
					printf("##########Error at Line #%d: Function definition should have at least one return statement.##########\n",linenum);
				}
				in_func_def = false;
				parameter_has_fault = false;
			}
		  | VOID ID L_PAREN R_PAREN
		 {
				funcReturnType = createExtType(VOID_t,0,0,NULL,NULL,0,false);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				if(node==NULL)//no declaration yet
				{
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
					insertTableNode(symbolTableList->global,newNode);
				}	
				else{
					struct FuncDeclNode *node2;
					node2 = searchFuncDeclList(func_decl_table,$2);
					if(node2 == NULL){
						printf("##########Error at Line #%d: Function has already been defined.##########\n",linenum);
					}
					else{
						if(node2->has_defined){
							printf("##########Error at Line #%d: Function has already been defined.##########\n",linenum);
						}
						
						
						if(node2->type->baseType != funcReturnType->baseType || node2->attr != NULL){
							printf("##########Error at Line #%d: Function definition doesn't match declaration.##########\n",linenum);
							node2->has_defined = false;
						}
						else{
							node2->has_defined = true;
						}
					}
				}
				free($2);
				
				func_def_type = VOID_t;
				in_func_def = true;
				has_return = false;
		}
		  compound_statement
		  {
				if(has_return){
					printf("##########Error at Line #%d: Function definition should not have return statement.##########\n",linenum);
				}
				in_func_def = false;
				parameter_has_fault = false;
		  }
		  | VOID ID L_PAREN parameter_list R_PAREN
		{
				funcReturnType = createExtType(VOID_t,0,0,NULL,NULL,0,false);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				struct Attribute *attr = createFunctionAttribute($4);
				if(node==NULL)//no declaration yet
				{
					if(parameter_has_fault == false){
						struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
						insertTableNode(symbolTableList->global,newNode);
					}
				}
				else{
					struct FuncDeclNode *node2;
					node2 = searchFuncDeclList(func_decl_table,$2);
					if(node2 == NULL){
						printf("##########Error at Line #%d: Function has already been defined.##########\n",linenum);
					}
					else{
						if(node2->has_defined){
							printf("##########Error at Line #%d: Function has already been defined.##########\n",linenum);
						}
						
						if(parameter_has_fault){
							printf("##########Error at Line #%d: Function definition is invalid.##########\n",linenum);
							node2->has_defined = false;
						}
						else if(node2->type->baseType != funcReturnType->baseType || node2->attr == NULL){
							printf("##########Error at Line #%d: Function definition doesn't match declaration.##########\n",linenum);
							node2->has_defined = false;
						}
						else if(node2->attr->funcParam->paramNum != attr->funcParam->paramNum){
							printf("##########Error at Line #%d: Function definition doesn't match declaration.##########\n",linenum);
							node2->has_defined = false;
						} 
						else if(!compareFuncAttrNode(node2->attr->funcParam->head,attr->funcParam->head)){
							printf("##########Error at Line #%d: Function definition doesn't match declaration.##########\n",linenum);
							node2->has_defined = false;
						}
						else{
							node2->has_defined = true;
						}
					}
				}
		}
		L_BRACE 
			{//enter a new scope
				++scope;
				AddSymTable(symbolTableList);
			//add parameters
				struct FuncAttrNode *attrNode = $4;
				while(attrNode!=NULL)
				{
					struct SymTableNode *newNode = createParameterNode(attrNode->name,scope,attrNode->value);
					insertTableNode(symbolTableList->tail,newNode);
					attrNode = attrNode->next;
				}
				func_def_type = VOID_t;
				in_func_def = true;
				has_return = false;
			}
			var_const_stmt_list R_BRACE
			{	
				if(Opt_SymTable == 1)
					printSymTable(symbolTableList->tail);
				deleteLastSymTable(symbolTableList);
				--scope;
				free($2);
				if(has_return){
					printf("##########Error at Line #%d: Function definition should not have return statement.##########\n",linenum);
				}
				in_func_def = false;
				parameter_has_fault = false;
			}
		  ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON
		{
			funcReturnType = createExtType($1,0,0,NULL,NULL,0,false);
			struct SymTableNode *node;
			node = findFuncDeclaration(symbolTableList->global,$2);
			if(node == NULL){
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
				insertTableNode(symbolTableList->global,newNode);
				func_decl_table = insertFuncDeclList(func_decl_table,newNode);
			}
			else{				
				struct FuncDeclNode *node2;
				node2 = searchFuncDeclList(func_decl_table,$2);
				if(node2 == NULL){
					printf("##########Error at Line #%d: Function declaration after definition.##########\n",linenum);
				}
				else{
					printf("##########Error at Line #%d: Function has already been declared.##########\n",linenum);
				}
			}
			free($2);
		}
	 	   | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON
		{
			funcReturnType = createExtType($1,0,0,NULL,NULL,0,false);
			struct Attribute *attr = createFunctionAttribute($4);
			struct SymTableNode *node;
			node = findFuncDeclaration(symbolTableList->global,$2);
			if(node == NULL){
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
				insertTableNode(symbolTableList->global,newNode);
				func_decl_table = insertFuncDeclList(func_decl_table,newNode);
			}
			else{
				struct FuncDeclNode *node2;
				node2 = searchFuncDeclList(func_decl_table,$2);
				if(node2 == NULL){
					printf("##########Error at Line #%d: Function declaration after definition.##########\n",linenum);
				}
				else{
					printf("##########Error at Line #%d: Function has already been declared.##########\n",linenum);
				}
			}
			free($2);
		}
		   | VOID ID L_PAREN R_PAREN SEMICOLON
		{
			funcReturnType = createExtType(VOID_t,0,0,NULL,NULL,0,false);
			struct SymTableNode *node;
			node = findFuncDeclaration(symbolTableList->global,$2);
			if(node == NULL){
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
				insertTableNode(symbolTableList->global,newNode);
				func_decl_table = insertFuncDeclList(func_decl_table,newNode);
			}
			else{
				struct FuncDeclNode *node2;
				node2 = searchFuncDeclList(func_decl_table,$2);
				if(node2 == NULL){
					printf("##########Error at Line #%d: Function declaration after definition.##########\n",linenum);
				}
				else{
					printf("##########Error at Line #%d: Function has already been declared.##########\n",linenum);
				}
			}
			free($2);
		}
		   | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON
		{
			funcReturnType = createExtType(VOID_t,0,0,NULL,NULL,0,false);
			struct Attribute *attr = createFunctionAttribute($4);
			struct SymTableNode *node;
			node = findFuncDeclaration(symbolTableList->global,$2);
			if(node == NULL){
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
				insertTableNode(symbolTableList->global,newNode);
				func_decl_table = insertFuncDeclList(func_decl_table,newNode);
			}
			else{
				struct FuncDeclNode *node2;
				node2 = searchFuncDeclList(func_decl_table,$2);
				if(node2 == NULL){
					printf("##########Error at Line #%d: Function declaration after definition.##########\n",linenum);
				}
				else{
					printf("##########Error at Line #%d: Function has already been declared.##########\n",linenum);
				}
			}
			free($2);
		}
		   ;

parameter_list : parameter_list COMMA scalar_type ID
		{
			struct FuncAttrNode *newNode;
			if($1 == NULL){
				newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
				newNode->value = createExtType($3,0,0,NULL,NULL,0,false);
				newNode->name = strdup($4);
				newNode->next = NULL;
				$$ = newNode;
			}
			else{
				if(findFuncAttrNode($1,$4)){
					printf("##########Error at Line #%d: Parameter \"%s\" has already been declared.##########\n",linenum,$4);
					newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
					newNode->value = createExtType($3,0,0,NULL,NULL,0,false);
					newNode->value->baseType = $3;//set correct type
					newNode->name = strdup($4);
					newNode->next = NULL;
					connectFuncAttrNode($1,newNode);
					$$ = $1;
				}
				else{
					newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
					newNode->value = createExtType($3,0,0,NULL,NULL,0,false);
					newNode->value->baseType = $3;//set correct type
					newNode->name = strdup($4);
					newNode->next = NULL;
					connectFuncAttrNode($1,newNode);
					$$ = $1;
				}
			}
			free($4);
		}
			   | parameter_list COMMA scalar_type array_decl
		{
			struct FuncAttrNode *newNode;
			if($1 == NULL){
				if($4->type == NULL){
					parameter_has_fault = true;
					$$ = NULL;
				}
				else{
					newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
					newNode->value = $4->type;//use pre-built ExtType(type is unknown)
					newNode->value->baseType = $3;//set correct type
					newNode->name = strdup($4->name);
					newNode->next = NULL;
					$$ = newNode;
				}
			}
			else{
				if($4->type == NULL){
					parameter_has_fault = true;
					$$ = $1;
				}
				else if(findFuncAttrNode($1,$4->name)){
					printf("##########Error at Line #%d: Parameter \"%s\" has already been declared.##########\n",linenum,$4->name);
					newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
					newNode->value = $4->type;//use pre-built ExtType(type is unknown)
					newNode->value->baseType = $3;//set correct type
					newNode->name = strdup($4->name);
					newNode->next = NULL;
					connectFuncAttrNode($1,newNode);
					$$ = $1;
				}
				else{
					newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
					newNode->value = $4->type;//use pre-built ExtType(type is unknown)
					newNode->value->baseType = $3;//set correct type
					newNode->name = strdup($4->name);
					newNode->next = NULL;
					connectFuncAttrNode($1,newNode);
					$$ = $1;
				}
			}
			free($4->name);
			free($4);
		}
			   | scalar_type array_decl
		{
			struct FuncAttrNode *newNode;
			if($2->type == NULL){
				newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
				newNode->value = $2->type;//use pre-built ExtType(type is unknown)
				newNode->name = strdup($2->name);
				newNode->next = NULL;
				parameter_has_fault = true;
			}
			else{
				newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
				newNode->value = $2->type;//use pre-built ExtType(type is unknown)
				newNode->value->baseType = $1;//set correct type
				newNode->name = strdup($2->name);
				newNode->next = NULL;
			}
			free($2->name);
			free($2);
			$$ = newNode;
		}
			   | scalar_type ID
		{
			struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
			newNode->value = createExtType($1,0,0,NULL,NULL,0,false);
			newNode->name = strdup($2);
			free($2);
			newNode->next = NULL;
			$$ = newNode;
		}
		;

var_decl : scalar_type identifier_list SEMICOLON
		{
			struct Variable* listNode = $2->head;
			struct SymTableNode *newNode;
			struct Variable* temp;
			
			while(listNode!=NULL)
			{	
				bool can_insert = true;
				if(listNode->type == NULL){
					printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable or array declaration.##########\n",linenum);
				}
				else if(listNode->array_initial){
					temp = listNode->array_initial->head;
					while(temp != NULL){
						//need to check
						if(temp->type == NULL){
							printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in array declaration.##########\n",linenum);
							break;
						}
						if($1 != FLOAT_t && $1 != DOUBLE_t){
							if($1 != temp->type->baseType){
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in array declaration.##########\n",linenum);
								break;
							}
							else{
								if(listNode->initial_success){
									newNode = createVariableNode(listNode->name,scope,listNode->type);
									newNode->type->baseType = $1;
									insertTableNode(symbolTableList->tail,newNode);
								}
							}
						}
						else if($1 == FLOAT_t){
							if(temp->type->baseType != INT_t && temp->type->baseType != FLOAT_t){
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in array declaration.##########\n",linenum);
								break;
							}
							else{
								if(listNode->initial_success){
									newNode = createVariableNode(listNode->name,scope,listNode->type);
									newNode->type->baseType = $1;
									insertTableNode(symbolTableList->tail,newNode);
								}
							}
						}
						else{
							if(temp->type->baseType != INT_t && temp->type->baseType != FLOAT_t && temp->type->baseType != DOUBLE_t){
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in array declaration.##########\n",linenum);
								break;
							}
							else{
								if(listNode->initial_success){
									newNode = createVariableNode(listNode->name,scope,listNode->type);
									newNode->type->baseType = $1;
									insertTableNode(symbolTableList->tail,newNode);
								}
							}
						}
						temp = temp->next;
					}
				}
				else{	
					if(listNode->type->has_initialvalue == false){
						if(listNode->initial_success){
							newNode = createVariableNode(listNode->name,scope,listNode->type);
							newNode->type->baseType = $1;
							insertTableNode(symbolTableList->tail,newNode);
						}
					}
					else if($1 != FLOAT_t && $1 != DOUBLE_t){
						if($1 != listNode->type->baseType){
							printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable declaration.##########\n",linenum);
						}
						else{
							if(listNode->initial_success){
								newNode = createVariableNode(listNode->name,scope,listNode->type);
								newNode->type->baseType = $1;
								insertTableNode(symbolTableList->tail,newNode);
							}
						}
					}
					else if($1 == FLOAT_t){
						if(listNode->type->baseType != INT_t && listNode->type->baseType != FLOAT_t){
							printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable declaration.##########\n",linenum);
						}
						else{
							if(listNode->initial_success){
								newNode = createVariableNode(listNode->name,scope,listNode->type);
								newNode->type->baseType = $1;
								insertTableNode(symbolTableList->tail,newNode);
							}
						}
					}
					else{
						if(listNode->type->baseType != INT_t && listNode->type->baseType != FLOAT_t && listNode->type->baseType != DOUBLE_t){
							printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable declaration.##########\n",linenum);
						}
						else{
							if(listNode->initial_success){
								newNode = createVariableNode(listNode->name,scope,listNode->type);
								newNode->type->baseType = $1;
								insertTableNode(symbolTableList->tail,newNode);
							}
						}
					}
					
				}
				listNode = listNode->next;
			}
			deleteVariableList($2);
		}
		 ;

identifier_list : identifier_list COMMA ID
		{
			struct ExtType *type = createExtType(VOID_t,0,false,NULL,NULL,0,false);//type unknown here
			struct Variable *newVariable = createVariable($3,type,NULL);
			
			struct SymTableNode *node = findSymTableNode(symbolTableList->tail,$3);
			if(node != NULL){
				printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$3);
				newVariable->initial_success = false;
			}
			else{
				struct Variable *head = $1->head;
				
				while(head != NULL){
					if(strncmp(head->name,$3,32) == 0){
						printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$3);
						newVariable->initial_success = false;
						break;
					}
					head = head->next;
				}
			}
				
			connectVariableList($1,newVariable);
			$$ = $1;

			free($3);
			
		}
		| identifier_list COMMA ID ASSIGN_OP logical_expression
		{	
			struct ExtType *type = NULL;
			bool failure = false;
			struct SymTableNode *node = findSymTableNode(symbolTableList->tail,$3);
			if(node != NULL){
				printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$3);
				failure = true;
			}
			else{
				struct Variable *head = $1->head;
				
				while(head != NULL){
					if(strncmp(head->name,$3,32) == 0){
						printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$3);
						failure = true;
						break;
					}
					head = head->next;
				}
			}

			if($5 != NULL){
				if($5->dim_smaller){
					printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
					failure = true;
				}
				else{
					type = $5;
					type->has_initialvalue = true;
				}
			}
			else{
				type = $5;
			}
			struct Variable *newVariable = createVariable($3,type,NULL);
			if(failure){
				newVariable->initial_success = false;
			}
			connectVariableList($1,newVariable);
			$$ = $1;
			free($3);
		}
		| identifier_list COMMA array_decl ASSIGN_OP initial_array
		{
			
			if(array_decl_has_fault){
				$3->initial_success = false;
			}
			else{
				struct Variable *head = $1->head;
				
				while(head != NULL){
					if(strncmp(head->name,$3->name,32) == 0){
						printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$3->name);
						$3->initial_success = false;
						break;
					}
					head = head->next;
				}
			}
			
			int size = 1;
			struct ArrayDimNode *temp = $3->type->dimArray;
			while(temp != NULL){
				size *= temp->size;
				temp = temp->next;
			}
			int count = 0;
			if($5 != NULL){
				struct Variable *current = $5->head;
				while(current != NULL){
					count++;
					current = current->next;
				}
				if(count > size){
					printf("##########Error at Line #%d: The number of array initializers should be equal to or less than the array size.##########\n",linenum);
					$3->initial_success = false;
					$3->array_initial = $5;
					$3->type->has_initialvalue = true;
				}
				else{
					$3->array_initial = $5;
					$3->type->has_initialvalue = true;
				}
			}
			else{
				$3->array_initial = $5;
				$3->type->has_initialvalue = false;
			}	

			connectVariableList($1,$3);
			$$ = $1;
			
			array_decl_has_fault = false;
		}
		| identifier_list COMMA array_decl
		{
			if(array_decl_has_fault){
				$3->initial_success = false;
			}
			else{
				struct Variable *temp = $1->head;
				
				while(temp != NULL){
					if(strncmp(temp->name,$3->name,32) == 0){
						printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$3->name);
						$3->initial_success = false;
						break;
					}
					temp = temp->next;
				}
			}
			connectVariableList($1,$3);
			$$ = $1;	
			
			array_decl_has_fault = false;
		}
		| array_decl ASSIGN_OP initial_array
		{
			if(array_decl_has_fault){
				$1->initial_success = false;
			}

			int size = 1;
			struct ArrayDimNode *temp = $1->type->dimArray;
			while(temp != NULL){
				size *= temp->size;
				temp = temp->next;
			}
			int count = 0;
			if($3 != NULL){
				struct Variable *current = $3->head;
				while(current != NULL){
					count++;
					current = current->next;
				}
				if(count > size){
					printf("##########Error at Line #%d: The number of array initializers should be equal to or less than the array size.##########\n",linenum);
					$1->initial_success = false;
					$1->array_initial = $3;
					$1->type->has_initialvalue = true;
				}
				else{
					$1->array_initial = $3;
					$1->type->has_initialvalue = true;
				}
			}
			else{
				$1->array_initial = $3;
				$1->type->has_initialvalue = false;
			}	
			$$ = createVariableList($1);
			
			array_decl_has_fault = false;
		}
		| array_decl
		{
			if(array_decl_has_fault){
				$1->initial_success = false;
				$$ = createVariableList($1);
			}
			else{
				$$ = createVariableList($1);
			}
			array_decl_has_fault = false;
		}
		| ID ASSIGN_OP logical_expression
		{
			struct ExtType *type = NULL;
			bool failure = false;
			struct SymTableNode *node = findSymTableNode(symbolTableList->tail,$1);
			if(node != NULL){
				printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$1);
				failure = true;
			}
			if($3 != NULL){
				if($3->dim_smaller){
					printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
					failure = true;
				}
				else{
					type = $3;
					type->has_initialvalue = true;
				}
			}
			else{
				type = $3;
			}
			struct Variable *newVariable = createVariable($1,type,NULL);
			if(failure){
				newVariable->initial_success = false;
			}
			$$ = createVariableList(newVariable);
			free($1);
		}
		| ID
		{
			struct ExtType *type = createExtType(VOID_t,0,false,NULL,NULL,0,false);//type unknown here
			struct Variable *newVariable = createVariable($1,type,NULL);
			struct SymTableNode *node = findSymTableNode(symbolTableList->tail,$1);
			if(node != NULL){
				printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$1);
				newVariable->initial_success = false;
			}	
			$$ = createVariableList(newVariable);
			
			free($1);
		}
				;

initial_array : L_BRACE literal_list R_BRACE
			{
				$$ = $2;
			}
			  ;

literal_list : literal_list COMMA logical_expression
			{
				if($3 != NULL){
					if($3->dim_smaller){
						printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
					}
				}
				struct ExtType *type = $3;
				struct Variable * newVariable = createVariable("arrayinitial",type,NULL);
				connectVariableList($1,newVariable);
				$$ = $1;
			}
			 | logical_expression
			 {
				if($1 != NULL){
					if($1->dim_smaller){
						printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
					}
				}
				struct ExtType *type = $1;
				struct Variable *newVariable = createVariable("arrayinitial",type,NULL);
				$$ = createVariableList(newVariable);
			 }
             |
			{
				$$ = NULL;
			}
			 ;

const_decl : CONST scalar_type const_list SEMICOLON
	{
		struct SymTableNode *list = $3;//symTableNode base on initailized data type, scalar_type is not used
		while(list!=NULL)
		{
			if($2 != FLOAT_t && $2 != DOUBLE_t){
				if(list->type->baseType != $2){
					printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in constant declaration.##########\n",linenum);
				}
				else{
					struct SymTableNode *temp = (struct SymTableNode*)malloc(sizeof(struct SymTableNode));
					temp->reference = list->reference;
					strncpy(temp->name,list->name,32);
					temp->kind = list->kind;
					temp->level = list->level;
					temp->type = list->type;
					temp->attr = list->attr;
					temp->next = NULL;
					insertTableNode(symbolTableList->tail,temp);
				}
			}
			else if($2 != DOUBLE_t){
				if(list->type->baseType != INT_t && list->type->baseType != FLOAT_t){
					printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in constant declaration.##########\n",linenum);
				}
				else{
					struct SymTableNode *temp = (struct SymTableNode*)malloc(sizeof(struct SymTableNode));
					temp->reference = list->reference;
					strncpy(temp->name,list->name,32);
					temp->kind = list->kind;
					temp->level = list->level;
					temp->type = list->type;
					temp->type->baseType = FLOAT_t;
					temp->attr = list->attr;
					temp->next = NULL;
					insertTableNode(symbolTableList->tail,temp);
				}
			}
			else{
				if(list->type->baseType != INT_t && list->type->baseType != FLOAT_t && list->type->baseType != DOUBLE_t){
					printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in constant declaration.##########\n",linenum);
				}
				else{
					struct SymTableNode *temp = (struct SymTableNode*)malloc(sizeof(struct SymTableNode));
					temp->reference = list->reference;
					strncpy(temp->name,list->name,32);
					temp->kind = list->kind;
					temp->level = list->level;
					temp->type = list->type;
					temp->type->baseType = DOUBLE_t;
					temp->attr = list->attr;
					temp->next = NULL;
					insertTableNode(symbolTableList->tail,temp);
				}
			}
			list = list->next;
		}
	}
;

const_list : const_list COMMA ID ASSIGN_OP literal_const
		{
			struct SymTableNode *node = findSymTableNode(symbolTableList->tail,$3);
			if(node != NULL){
				printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$3);
			}
			else{
				struct ExtType *type = createExtType($5->constVal->type,0,false,NULL,NULL,0,true);
				if($1 == NULL){
					$$ = createConstNode($3,scope,type,$5);
				}
				else{
					struct SymTableNode *temp = $1;
					bool success = true;
					if(strncmp(temp->name,$3,32) == 0){
						success = false;
						printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$3);
					}
					while(temp->next!=NULL)
					{
						if(strncmp(temp->name,$3,32) == 0){
							success = false;
							printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$3);
							break;
						}
						temp = temp->next;
					}
					if(success){
						temp->next = createConstNode($3,scope,type,$5);
					}	
				}
					
			}
			
			free($3);
		}
		   | ID ASSIGN_OP literal_const
                {
			struct SymTableNode *node = findSymTableNode(symbolTableList->tail,$1);
			if(node != NULL){
				printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$1);
			} 
			else{
				struct ExtType *type = createExtType($3->constVal->type,0,false,NULL,NULL,0,true);
				$$ = createConstNode($1,scope,type,$3);
			}
				
			free($1);
		}    
		   ;

array_decl : ID dim
	{	
		struct ArrayDimNode * current = $2;
		bool failure = false;
		struct SymTableNode *node = findSymTableNode(symbolTableList->tail,$1);
		if(node != NULL){
			printf("##########Error at Line #%d: \"%s\" has already been declared.##########\n",linenum,$1);
			array_decl_has_fault = true;
		}
		while(current != NULL){
			if(current->size <= 0){
				printf("##########Error at Line #%d: The index must be greater than zero in an array declaration.##########\n",linenum);
				break;
			}
			current = current->next;
		}
		struct ExtType *type;
		if(failure){
			type = createExtType(VOID_t,0,true,$2,NULL,0,false);
			parameter_has_fault = true;
		}
		else{
			type = createExtType(VOID_t,0,true,$2,NULL,0,false);//type unknown here
		}
		struct Variable *newVariable = createVariable($1,type,NULL);
		free($1);
		$$ = newVariable;
	}
		   ;

dim : dim ML_BRACE INT_CONST MR_BRACE
	{
	  	connectArrayDimNode($1,createArrayDimNode($3));
		$$ = $1;
	}
	| ML_BRACE INT_CONST MR_BRACE
	{
		$$ = createArrayDimNode($2);
	}
	;

compound_statement : L_BRACE 
			{//enter a new scope
				++scope;
				AddSymTable(symbolTableList);
			}
			var_const_stmt_list R_BRACE
			{	
				if(Opt_SymTable == 1)
					printSymTable(symbolTableList->tail);
				deleteLastSymTable(symbolTableList);
				--scope;
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

simple_statement :variable_reference ASSIGN_OP logical_expression SEMICOLON
				{
					if($1 == NULL){
						if($3 == NULL){
							printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
						}
						else if($3->isArray){
							if($3->dim_smaller){
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
						}
						else{
							printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);

						}	
					}
					else if($3 == NULL){
						if($1->kind == CONSTANT_t){
							printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
						}
						if($1->type->isArray){
							if($1->type->dim_smaller){
								printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);	
							}
						}
						else{
							printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
						}
					}
					else{
						if($1->kind == CONSTANT_t){
							printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
						}
						if($1->type->isArray && $1->type->dim_smaller){
							if($3->isArray && $3->dim_smaller){
								printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
		
							}
							else{
								printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
						}
						else if($3->isArray && $3->dim_smaller){
							printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
							printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
						}
						else{
							if($1->type->baseType != FLOAT_t && $1->type->baseType != DOUBLE_t){
								if($1->type->baseType != $3->baseType){
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
							else if($1->type->baseType == FLOAT_t){
								if($3->baseType != INT_t && $3->baseType != FLOAT_t){
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
							else{
								if($3->baseType != INT_t && $3->baseType != FLOAT_t && $3->baseType != DOUBLE_t){
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
						}
					}
				}
				 | PRINT logical_expression SEMICOLON
				 {
					if($2 != NULL){
						if($2->dim_smaller){
							printf("##########Error at Line #%d: Variable references in print statement must be scalar type.##########\n",linenum);
						}
					}
					else{
						printf("##########Error at Line #%d: Variable references in print statement must be scalar type.##########\n",linenum);
					}
				 }
				 | READ variable_reference SEMICOLON
				 {	
					if($2 == NULL){
						printf("##########Error at Line #%d: Variable references in read statement must be scalar type.##########\n",linenum);
					}
					else{ 
						if($2->type != NULL){
							if($2->type->dim_smaller){
								printf("##########Error at Line #%d: Variable references in read statement must be scalar type.##########\n",linenum);
							}
						}
						else{
							printf("##########Error at Line #%d: Variable references in read statement must be scalar type.##########\n",linenum);
						}
					}
					
				 }
				 ;

conditional_statement : IF L_PAREN logical_expression R_PAREN
					{
						if($3 == NULL){
							printf("##########Error at Line #%d: The conditional expression part of if statement must be bool type.##########\n",linenum);
						}
						else if($3->isArray){
							if($3->dim_smaller){
								printf("##########Error at Line #%d: The conditional expression part of if statement must be bool type.##########\n",linenum);
							}
						}
						else if($3->baseType != BOOL_t){
							printf("##########Error at Line #%d: The conditional expression part of if statement must be bool type.##########\n",linenum);
						}
					}
					compound_statement else_statement
					;
					
else_statement : ELSE compound_statement
				 |
				;
while_statement : WHILE
		{//enter a new scope
			++scope;
			AddSymTable(symbolTableList);
			
			break_allow++;
			continue_allow++;
		}
		L_PAREN logical_expression R_PAREN
		{
			if($4 == NULL){
				printf("##########Error at Line #%d: The conditional expression part of while statement must be bool type.##########\n",linenum);
			}
			else if($4->isArray){
				if($4->dim_smaller){
					printf("##########Error at Line #%d: The conditional expression part of while statement must be bool type.##########\n",linenum);
				}
			}
			else if($4->baseType != BOOL_t){
				printf("##########Error at Line #%d: The conditional expression part of while statement must be bool type.##########\n",linenum);
			}
		}
		L_BRACE var_const_stmt_list R_BRACE
		{	
			if(Opt_SymTable == 1)
				printSymTable(symbolTableList->tail);
			deleteLastSymTable(symbolTableList);
			--scope;
			
			break_allow--;
			continue_allow--;
		}
		| DO L_BRACE
		{//enter a new scope
			++scope;
			AddSymTable(symbolTableList);
			
			break_allow++;
			continue_allow++;
		}
		var_const_stmt_list
		 R_BRACE WHILE L_PAREN logical_expression R_PAREN SEMICOLON
		{
			if($8 == NULL){
				printf("##########Error at Line #%d: The conditional expression part of while statement must be bool type.##########\n",linenum);
			}
			else if($8->isArray){
				if($8->dim_smaller){
					printf("##########Error at Line #%d: The conditional expression part of while statement must be bool type.##########\n",linenum);
				}
			}
			else if($8->baseType != BOOL_t){
				printf("##########Error at Line #%d: The conditional expression part of while statement must be bool type.##########\n",linenum);
			}
			
			if(Opt_SymTable == 1)
				printSymTable(symbolTableList->tail);
			deleteLastSymTable(symbolTableList);
			--scope;
			
			break_allow--;
			continue_allow--;
		}
		;

for_statement : FOR
		{//enter a new scope
			++scope;
			AddSymTable(symbolTableList);
			
			break_allow++;
			continue_allow++;
		}
		L_PAREN initial_expression_list SEMICOLON control_expression_list SEMICOLON increment_expression_list R_PAREN 
					L_BRACE var_const_stmt_list R_BRACE
		{
			if(Opt_SymTable == 1)
				printSymTable(symbolTableList->tail);
			deleteLastSymTable(symbolTableList);
			--scope;
			
			break_allow--;
			continue_allow--;
		}
		;

initial_expression_list : initial_expression
				  	    |
				        ;

initial_expression : initial_expression COMMA variable_reference ASSIGN_OP logical_expression
					{
						if($3 == NULL){
							if($5 == NULL){
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
							else if($5->isArray){
								if($5->dim_smaller){
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
	
							}	
						}
						else if($5 == NULL){
							if($3->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($3->type->isArray){
								if($3->type->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);	
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
						}
						else{
							if($3->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($3->type->isArray && $3->type->dim_smaller){
								if($5->isArray && $5->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
			
								}
								else{
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
							else if($5->isArray && $5->dim_smaller){
								printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
							else{
								if($3->type->baseType != FLOAT_t && $3->type->baseType != DOUBLE_t){
									if($3->type->baseType != $5->baseType){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
								else if($3->type->baseType == FLOAT_t){
									if($5->baseType != INT_t && $5->baseType != FLOAT_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
								else{
									if($5->baseType != INT_t && $5->baseType != FLOAT_t && $5->baseType != DOUBLE_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
							}
						//do something
						}
					}
				   | initial_expression COMMA logical_expression
				   {
						//do nothing

				   }
				   | logical_expression{
						//do nothing
				   }
				   |variable_reference ASSIGN_OP logical_expression
				   {
						if($1 == NULL){
							if($3 == NULL){
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
							else if($3->isArray){
								if($3->dim_smaller){
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
	
							}	
						}
						else if($3 == NULL){
							if($1->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($1->type->isArray){
								if($1->type->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);	
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
						}
						else{
							if($1->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($1->type->isArray && $1->type->dim_smaller){
								if($3->isArray && $3->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
			
								}
								else{
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
							else if($3->isArray && $3->dim_smaller){
								printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
							else{
								if($1->type->baseType != FLOAT_t && $1->type->baseType != DOUBLE_t){
									if($1->type->baseType != $3->baseType){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
								else if($1->type->baseType == FLOAT_t){
									if($3->baseType != INT_t && $3->baseType != FLOAT_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
								else{
									if($3->baseType != INT_t && $3->baseType != FLOAT_t && $3->baseType != DOUBLE_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
							}
						}
					}
					;
control_expression_list : control_expression
				  		|
				  		;

control_expression : control_expression COMMA variable_reference ASSIGN_OP logical_expression
					{
						if($3 == NULL){
							if($5 == NULL){
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
							}
							else if($5->isArray){
								if($5->dim_smaller){
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
							}	
						}
						else if($5 == NULL){
							if($3->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($3->type->isArray){
								if($3->type->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									if($3->type->baseType != BOOL_t){
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}	
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								if($3->type->baseType != BOOL_t){
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
							}
						}
						else{
							if($3->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($3->type->isArray && $3->type->dim_smaller){
								if($5->isArray && $5->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
							}
							else if($5->isArray && $5->dim_smaller){
								printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								if($3->type->baseType != BOOL_t){
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
							}
							else if($3->type->baseType != BOOL_t){
								if($3->type->baseType != FLOAT_t && $3->type->baseType != DOUBLE_t){
									if($3->type->baseType != $5->baseType){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
									else{
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
								}
								else if($3->type->baseType == FLOAT_t){
									if($5->baseType != INT_t && $5->baseType != FLOAT_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
									else{
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
								}
								else{
									if($5->baseType != INT_t && $5->baseType != FLOAT_t && $5->baseType != DOUBLE_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
									else{
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
								}
							}
							else{
								if($5->baseType != BOOL_t){
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
						}
					}
				   | control_expression COMMA logical_expression
				   {
						if($3 == NULL){
							printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
						}
						else if($3->isArray){
							if($3->dim_smaller){
								printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
							}
						}
						else{
							if($3->baseType != BOOL_t){
								printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
							}
						}
				   }
				   | logical_expression
				   {	
						if($1 == NULL){
							printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
						}
						else if($1->isArray){
							if($1->dim_smaller){
								printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
							}
						}
						else{
							if($1->baseType != BOOL_t){
								printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
							}
						}
				   }
				   |variable_reference ASSIGN_OP logical_expression
				   {	
						if($1 == NULL){
							if($3 == NULL){
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
							}
							else if($3->isArray){
								if($3->dim_smaller){
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
							}	
						}
						else if($3 == NULL){
							if($1->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($1->type->isArray){
								if($1->type->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									if($1->type->baseType != BOOL_t){
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}	
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								if($1->type->baseType != BOOL_t){
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
							}
						}
						else{
							if($1->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($1->type->isArray && $1->type->dim_smaller){
								if($3->isArray && $3->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
							}
							else if($3->isArray && $3->dim_smaller){
								printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								if($1->type->baseType != BOOL_t){
									printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
								}
							}
							else if($1->type->baseType != BOOL_t){
								if($1->type->baseType != FLOAT_t && $1->type->baseType != DOUBLE_t){
									if($1->type->baseType != $3->baseType){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
									else{
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
								}
								else if($1->type->baseType == FLOAT_t){
									if($3->baseType != INT_t && $3->baseType != FLOAT_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
									else{
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
								}
								else{
									if($3->baseType != INT_t && $3->baseType != FLOAT_t && $3->baseType != DOUBLE_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
									else{
										printf("##########Error at Line #%d: The control expression must be of boolean type.##########\n",linenum);
									}
								}
							}
							else{
								if($3->baseType != BOOL_t){
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
						}
				   }
				   ;

increment_expression_list : increment_expression 
						  |
						  ;

increment_expression : increment_expression COMMA variable_reference ASSIGN_OP logical_expression
					{
						if($3 == NULL){
							if($5 == NULL){
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
							else if($5->isArray){
								if($5->dim_smaller){
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
	
							}	
						}
						else if($5 == NULL){
							if($3->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($3->type->isArray){
								if($3->type->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);	
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
						}
						else{
							if($3->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($3->type->isArray && $3->type->dim_smaller){
								if($5->isArray && $5->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
			
								}
								else{
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
							else if($5->isArray && $5->dim_smaller){
								printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
							else{
								if($3->type->baseType != FLOAT_t && $3->type->baseType != DOUBLE_t){
									if($3->type->baseType != $5->baseType){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
								else if($3->type->baseType == FLOAT_t){
									if($5->baseType != INT_t && $5->baseType != FLOAT_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
								else{
									if($5->baseType != INT_t && $5->baseType != FLOAT_t && $5->baseType != DOUBLE_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
							}
						//do something
						}
					}
					 | increment_expression COMMA logical_expression
					 {
						//do nothing
					 }
					 | logical_expression
					 {
						//do nothing
					 }
					 |variable_reference ASSIGN_OP logical_expression
					 {
						if($1 == NULL){
							if($3 == NULL){
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
							else if($3->isArray){
								if($3->dim_smaller){
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
	
							}	
						}
						else if($3 == NULL){
							if($1->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($1->type->isArray){
								if($1->type->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
								else{
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);	
								}
							}
							else{
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
						}
						else{
							if($1->kind == CONSTANT_t){
								printf("##########Error at Line #%d: Re-assignments to constants are not allowed.##########\n",linenum);
							}
							if($1->type->isArray && $1->type->dim_smaller){
								if($3->isArray && $3->dim_smaller){
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
			
								}
								else{
									printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
									printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
								}
							}
							else if($3->isArray && $3->dim_smaller){
								printf("##########Error at Line #%d: Array assignment are not allowed.##########\n",linenum);
								printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
							}
							else{
								if($1->type->baseType != FLOAT_t && $1->type->baseType != DOUBLE_t){
									if($1->type->baseType != $3->baseType){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
								else if($1->type->baseType == FLOAT_t){
									if($3->baseType != INT_t && $3->baseType != FLOAT_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
								else{
									if($3->baseType != INT_t && $3->baseType != FLOAT_t && $3->baseType != DOUBLE_t){
										printf("##########Error at Line #%d: The type of right-hand side doesn't match left-hand side in variable reference assignment.##########\n",linenum);
									}
								}
							}
						}
					 }
					 ;

function_invoke_statement : ID L_PAREN logical_expression_list R_PAREN SEMICOLON
						{
							struct SymTableNode *node;
							node = findFuncDeclaration(symbolTableList->global,$1);
							if(node == NULL){
								printf("##########Error at Line #%d: Function invocation doesn't match any function declaration or definition.##########\n",linenum);
							}
							else if(node->attr == NULL){
								printf("##########Error at Line #%d: Function invocation doesn't match any function declaration or definition.##########\n",linenum);
							}
							else{
								if($3 == NULL){
									printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
								}
								else{
									struct FuncAttrNode *current1 = node->attr->funcParam->head;
									struct Variable *current2 = $3->head;
									bool success = true;
									struct ArrayDimNode* array1;
									struct ArrayDimNode* array2;
									while(current1 != NULL || current2 != NULL){
										if(current1 == NULL){
											printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);

											success = false;
											break;
										}
										else if(current2 == NULL){
											printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
											success = false;
											break;
										}
										else if(current1->value->isArray != current2->type->isArray){
											printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
											success = false;
											break;
										}
										else if(current1->value->isArray == false){
											if(current1->value->baseType != FLOAT_t && current1->value->baseType != DOUBLE_t){
												if(current2->type->baseType != current1->value->baseType){
													printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
													success = false;
													break;
												}
											}
											else if(current1->value->baseType != DOUBLE_t){
												if(current2->type->baseType != INT_t && current2->type->baseType != FLOAT_t){
													printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
													success = false;
													break;
												}
											}
											else{
												if(current2->type->baseType != INT_t && current2->type->baseType != FLOAT_t && current2->type->baseType != DOUBLE_t){
													printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
													success = false;
													break;
												}
											}
										}
										else if(current1->value->baseType != current2->type->baseType || current2->type->dim_count != 0){
											printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
											success = false;
											break;
										}
										else if(current1->value->dim != current2->type->dim){
											printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
											success = false;
											break;
										}
										else{
											array1 = current1->value->dimArray;
											array2 = current2->type->dimArray;
											if(array1 == NULL || array2 == NULL){
												printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
												success = false;
												break;
											}
											else{
												bool flag = false;
												while(array1 != NULL || array2 != NULL){
													if(array1 == NULL){
														printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
														success = false;
														flag = true;
														break;
													}
													else if(array2 == NULL){
														printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
														success = false;
														flag = true;
														break;
													}
													else if(array1->size != array2->size){
														printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
														success = false;
														flag = true;
														break;
													}
													array1 = array1->next;
													array2 = array2->next;
												}
												if(flag){
													break;
												}
											}
										}
										current1 = current1->next;
										current2 = current2->next;
									}
									if(success){
										struct ExtType *temp = createExtType(node->type->baseType,0,false,NULL,NULL,0,false);
									}
								}
							}
							
							free($1);
						}
						  | ID L_PAREN R_PAREN SEMICOLON
						{
							struct SymTableNode *node;
							node = findFuncDeclaration(symbolTableList->global,$1);
							if(node == NULL){
								printf("##########Error at Line #%d: Function invocation doesn't match any function declaration or definition.##########\n",linenum);
							}
							else if(node->attr != NULL){
								printf("##########Error at Line #%d: Function invocation doesn't match any function declaration or definition.##########\n",linenum);
							}
							else{
								struct ExtType *temp = createExtType(node->type->baseType,0,false,NULL,NULL,0,false);
							}
							free($1);
						}
						  ;

jump_statement : CONTINUE SEMICOLON
				{
					if(continue_allow == 0){
						printf("##########Error at Line #%d: Continue can only appear in loop statement.##########\n",linenum);
					}
				}
			   | BREAK SEMICOLON
			   {
					if(break_allow == 0){
						printf("##########Error at Line #%d: Break can only appear in loop statement.##########\n",linenum);
					}
			   }
			   | RETURN logical_expression SEMICOLON
			   {	
					if(in_func_def){
						has_return = true;
						if($2 == NULL){
							printf("##########Error at Line #%d: The type of the return statement inside the function must match the return type of the function declaration/definition.##########\n",linenum);
						}
						else if($2->isArray){
							if($2->dim_smaller){
								printf("##########Error at Line #%d: The return value must be a scalar type.##########\n",linenum);
								printf("##########Error at Line #%d: The type of the return statement inside the function must match the return type of the function declaration/definition.##########\n",linenum);
							}
							else{
								if(func_def_type == VOID_t){
									printf("##########Error at Line #%d: The type of the return statement inside the function must match the return type of the function declaration/definition.##########\n",linenum);
								}
								else if(func_def_type != FLOAT_t && func_def_type != DOUBLE_t){
									if($2->baseType != func_def_type){
										printf("##########Error at Line #%d: The type of the return statement inside the function must match the return type of the function declaration/definition.##########\n",linenum);
									}
								}
								else if(func_def_type != FLOAT_t){
									if($2->baseType != INT_t && $2->baseType != FLOAT_t){
										printf("##########Error at Line #%d: The type of the return statement inside the function must match the return type of the function declaration/definition.##########\n",linenum);
									}
								}
								else{
									if($2->baseType != INT_t && $2->baseType != FLOAT_t && $2->baseType != DOUBLE_t){
										printf("##########Error at Line #%d: The type of the return statement inside the function must match the return type of the function declaration/definition.##########\n",linenum);
									}
								}
							}
						}
						else{
							if(func_def_type == VOID_t){
								printf("##########Error at Line #%d: The type of the return statement inside the function must match the return type of the function declaration/definition.##########\n",linenum);
							}
							else if(func_def_type != FLOAT_t && func_def_type != DOUBLE_t){
								if($2->baseType != func_def_type){
									printf("##########Error at Line #%d: The type of the return statement inside the function must match the return type of the function declaration/definition.##########\n",linenum);
								}
							}
							else if(func_def_type != DOUBLE_t){
								if($2->baseType != INT_t && $2->baseType != FLOAT_t){
									printf("##########Error at Line #%d: The type of the return statement inside the function must match the return type of the function declaration/definition.##########\n",linenum);
								}
							}
							else{
								if($2->baseType != INT_t && $2->baseType != FLOAT_t && $2->baseType != DOUBLE_t){
									printf("##########Error at Line #%d: The type of the return statement inside the function must match the return type of the function declaration/definition.##########\n",linenum);
								}
							}
						}
						
					}
			   }
			   ;

variable_reference : array_list
					{
						$$ = $1;
					}
				   | ID
				   {
						struct SymTableNode *node = NULL;
						struct SymTable *current = symbolTableList->tail;
						while(current != NULL){
							node = findSymTableNode(current,$1);
							if(node != NULL){
								break;
							}
							current = current->prev;
						}
						
						if(node == NULL){
							$$ = NULL;
							printf("##########Error at Line #%d: ReferenceError: variable \"%s\" is undefined.##########\n",linenum,$1);
						}
						else{
							if(node->type->isArray){
								node->type->dim_smaller = true;
								node->type->dim_count = 0;
							}
							$$ = node;
						}
						
						free($1);
					}
				   ;


logical_expression : logical_expression OR_OP logical_term 
					{
						$$ = OR_OPcheck($1,$3,linenum);
					}
				   | logical_term 
				   {	
						$$ = $1;
					}
				   ;

logical_term : logical_term AND_OP logical_factor
			{
				$$ = AND_OPcheck($1,$3,linenum);
			}
			 | logical_factor 
			 {
				$$ = $1;
			}
			 ;

logical_factor : NOT_OP logical_factor
				{
					$$ = NOT_OPcheck($2,linenum);
				}
			   | relation_expression 
			   {
					$$ = $1;
				}
			   ;

relation_expression : arithmetic_expression relation_operator arithmetic_expression
					{
						if($2 == EQ_t || $2 == NE_t){
							$$ = rel_op2check($1,$3,$2,linenum);
						}
						else{
							$$ = rel_op4check($1,$3,$2,linenum);
						}
					}
					| arithmetic_expression 
					{
						$$ = $1;
					}
					;

relation_operator : LT_OP
					{
						$$ = LT_t;
					}
				  | LE_OP
					{
						$$ = LE_t;
					}
				  | EQ_OP
					{
						$$ = EQ_t;
					}
				  | GE_OP
					{
						$$ = GE_t;
					}
				  | GT_OP
					{
						$$ = GT_t;
					}
				  | NE_OP
					{
						$$ = NE_t;
					}
				  ;

arithmetic_expression : arithmetic_expression ADD_OP term
			{
				$$ = ADD_OPcheck($1,$3,linenum);
			}
		   | arithmetic_expression SUB_OP term
		   {
				$$ = SUB_OPcheck($1,$3,linenum);
		   }
           | relation_expression 
		   {
				$$ = $1;
			}
		   | term 
		   {
				$$ = $1;
			}
		   ;

term : term MUL_OP factor
		{
			$$ = MUL_OPcheck($1,$3,linenum);
		}
     | term DIV_OP factor
		{
			$$ = DIV_OPcheck($1,$3,linenum);
		}
	 | term MOD_OP factor
		{
			$$ = MOD_OPcheck($1,$3,linenum);
		}
	 | factor 
		{
			$$ = $1;
		}
	 ;

factor :variable_reference
		{	
			if($1 != NULL){
				$$ = $1->type;
			}
			else{
				$$ = NULL;
			}
		}
	   | SUB_OP factor
	   {
			$$ = unarySUB_OPcheck($2,linenum);
	   }
	   | L_PAREN logical_expression R_PAREN {$$ = $2;}
	   | ID L_PAREN logical_expression_list R_PAREN
	   {	
			struct SymTableNode *node;
			node = findFuncDeclaration(symbolTableList->global,$1);
			if(node == NULL){
				printf("##########Error at Line #%d: Function invocation doesn't match any function declaration or definition.##########\n",linenum);
				$$ = NULL;
			}
			else if(node->attr == NULL){
				printf("##########Error at Line #%d: Function invocation doesn't match any function declaration or definition.##########\n",linenum);
				$$ = NULL;
			}
			else{
				if($3 == NULL){
					printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
					$$ = NULL;
				}
				else{
					struct FuncAttrNode *current1 = node->attr->funcParam->head;
					struct Variable *current2 = $3->head;
					bool success = true;
					struct ArrayDimNode* array1;
					struct ArrayDimNode* array2;
					while(current1 != NULL || current2 != NULL){
						if(current1 == NULL){
							printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
							$$ = NULL;
							success = false;
							break;
						}
						else if(current2 == NULL){
							printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
							$$ = NULL;
							success = false;
							break;
						}
						else if(current1->value->isArray != current2->type->isArray){
							printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
							$$ = NULL;
							success = false;
							break;
						}
						else if(current1->value->isArray == false){
							if(current1->value->baseType != FLOAT_t && current1->value->baseType != DOUBLE_t){
								if(current2->type->baseType != current1->value->baseType){
									printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
									$$ = NULL;
									success = false;
									break;
								}
							}
							else if(current1->value->baseType != DOUBLE_t){
								if(current2->type->baseType != INT_t && current2->type->baseType != FLOAT_t){
									printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
									$$ = NULL;
									success = false;
									break;
								}
							}
							else{
								if(current2->type->baseType != INT_t && current2->type->baseType != FLOAT_t && current2->type->baseType != DOUBLE_t){
									printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
									$$ = NULL;
									success = false;
									break;
								}
							}
						}
						else if(current1->value->baseType != current2->type->baseType || current2->type->dim_count != 0){
							printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
							$$ = NULL;
							success = false;
							break;
						}
						else if(current1->value->dim != current2->type->dim){
							printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
							$$ = NULL;
							success = false;
							break;
						}
						else{
							array1 = current1->value->dimArray;
							array2 = current2->type->dimArray;
							if(array1 == NULL || array2 == NULL){
								printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
								$$ = NULL;
								success = false;
								break;
							}
							else{
							    bool flag = false;
								while(array1 != NULL || array2 != NULL){
									if(array1 == NULL){
										printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
										$$ = NULL;
										success = false;
										flag = true;
										break;
									}
									else if(array2 == NULL){
										printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
										$$ = NULL;
										success = false;
										flag = true;
										break;
									}
									else if(array1->size != array2->size){
										printf("##########Error at Line #%d: Function invocation doesn't match function declaration or definition.##########\n",linenum);
										$$ = NULL;
										success = false;
										flag = true;
										break;
									}
									array1 = array1->next;
									array2 = array2->next;
								}
								if(flag){
									break;
								}
							}
						}
						current1 = current1->next;
						current2 = current2->next;
					}
					if(success){
						struct ExtType *temp = createExtType(node->type->baseType,0,false,NULL,NULL,0,false);
						$$ = temp;
					}
				}
			}
			
			free($1);
		}
	   | ID L_PAREN R_PAREN
	   {
			struct SymTableNode *node;
			node = findFuncDeclaration(symbolTableList->global,$1);
			if(node == NULL){
				printf("##########Error at Line #%d: Function invocation doesn't match any function declaration or definition.##########\n",linenum);
				$$ = NULL;
			}
			else if(node->attr != NULL){
				printf("##########Error at Line #%d: Function invocation doesn't match any function declaration or definition.##########\n",linenum);
				$$ = NULL;
			}
			else{
				struct ExtType *temp = createExtType(node->type->baseType,0,false,NULL,NULL,0,false);
				$$ = temp;
			}
			free($1);
		}
	   | literal_const
	   {
			int intvalue = 0;
			if($1->constVal->type == INT_t){
				intvalue = $1->constVal->value.integerVal;
			}
			struct ExtType *temp = createExtType($1->constVal->type,intvalue,false,NULL,NULL,0,false);
			$$ = temp;
			killAttribute($1);
	   }
	   ;

logical_expression_list : logical_expression_list COMMA logical_expression
						{
							if($1 == NULL){
								$$ = NULL;
							}
							else if($3 == NULL){
								$$ = NULL;
							}
							else if($3->baseType == VOID_t){
								$$ = NULL;
							}
							else{
								struct Variable *node = createVariable("func_invocation",$3,NULL);
								connectVariableList($1,node);
								$$ = $1;
							}
						}
						| logical_expression
						{	
							struct Variable *node;
							if($1 == NULL){
								$$ = NULL;
							}
							else if($1->baseType == VOID_t){
								$$ = NULL;
							}
							else{
								node = createVariable("func_invocation",$1,NULL);
								$$ = createVariableList(node);
							}
						}
						;

array_list : ID dimension
			{
				struct SymTableNode *node;
				struct SymTable *current = symbolTableList->tail;
				while(current != NULL){
					node = findSymTableNode(current,$1);
					if(node != NULL && node->type->isArray){
						break;
					}
					current = current->prev;
				}
				
				if(node == NULL){
					printf("##########Error at Line #%d: ReferenceError: array \"%s\" is undefined.##########\n",linenum,$1);
					$$ = NULL;
				}
				else if(!node->type->isArray){
					printf("##########Error at Line #%d: ReferenceError: \"%s\" is not an array.##########\n",linenum,$1);
					$$ = NULL;
				}
				else{
					bool arraycheck = true;
					struct ArrayDimNode *current1 = $2;
					int dimcount = 0;
					while(current1 != NULL){
						if(current1->size < 0){
							printf("##########Error at Line #%d: The index of array \"%s\" references is smaller than zero.##########\n",linenum,$1);
							arraycheck = false;
							$$ = NULL;
							break;
						}
						dimcount++;
						current1 = current1->next;
					}
					if(arraycheck){
						if(dimcount > node->type->dim){
							printf("##########Error at Line #%d: The dimension of array \"%s\" references is too big.##########\n",linenum,$1);
							$$ = NULL;
						}
						else{	
							if(dimcount < node->type->dim){
								node->type->dim_smaller = true;
								node->type->dim_count = dimcount;
							}
							$$ = node;
						}
					}	
				}
				free($1);
			}
		   ;

dimension : dimension ML_BRACE logical_expression MR_BRACE	
		  {
				if($3->baseType != INT_t){
					printf("##########Error at Line #%d: The index of array is not an integer type.##########\n",linenum);
					connectArrayDimNode($1,createArrayDimNode(0));
					$$ = $1;
				}
				else if($3->isArray){
					if($3->dim_smaller){
						printf("##########Error at Line #%d: The index of array can't be an array.##########\n",linenum);
						connectArrayDimNode($1,createArrayDimNode(0));
						$$ = $1;
					}
					else{
						connectArrayDimNode($1,createArrayDimNode(0));
						$$ = $1;
					}
				}
				else{
					if($3->intvalue < 0){
						printf("##########Error at Line #%d: The index of array can't be negative number.##########\n",linenum);
						connectArrayDimNode($1,createArrayDimNode(0));
						$$ = $1;
					}
					else{
						connectArrayDimNode($1,createArrayDimNode($3->intvalue));
						$$ = $1;
					}
					
				}
				
		  }
		  | ML_BRACE logical_expression MR_BRACE
		  {
				if($2->baseType != INT_t){
					printf("##########Error at Line #%d: The index of array is not an integer type.##########\n",linenum);
					$$ = createArrayDimNode(0);
				}
				else if($2->isArray){
					if($2->dim_smaller){
						printf("##########Error at Line #%d: The index of array can't be an array.##########\n",linenum);
						$$ = createArrayDimNode(0);
					}
					else{
						$$ = createArrayDimNode(0);
					}
				}
				else{
					if($2->intvalue < 0){
						printf("##########Error at Line #%d: The index of array can't be negative number.##########\n",linenum);
						$$ = createArrayDimNode(0);
					}
					else{
						$$ = createArrayDimNode($2->intvalue);
					}
				}
				
		  }
		  ;



scalar_type : INT
		{
			$$ = INT_t;
		}
		| DOUBLE
		{
			$$ = DOUBLE_t;
		}
		| STRING
		{
			$$ = STRING_t;
		}
		| BOOL
		{
			$$ = BOOL_t;
		}
		| FLOAT
		{
			$$ = FLOAT_t;
		}
		;
 
literal_const : INT_CONST
		{
			int val = $1;
			$$ = createConstantAttribute(INT_t,&val);		
		}
			  | SUB_OP INT_CONST
		{
			int val = -$2;
			$$ = createConstantAttribute(INT_t,&val);
		}
			  | FLOAT_CONST
		{
			float val = $1;
			$$ = createConstantAttribute(FLOAT_t,&val);
		}
			  | SUB_OP FLOAT_CONST
		{
			float val = -$2;
			$$ = createConstantAttribute(FLOAT_t,&val);
		}
			  | SCIENTIFIC
		{
			double val = $1;
			$$ = createConstantAttribute(DOUBLE_t,&val);
		}
			  | SUB_OP SCIENTIFIC
		{
			double val = -$2;
			$$ = createConstantAttribute(DOUBLE_t,&val);
		}
			  | STR_CONST
		{
			$$ = createConstantAttribute(STRING_t,$1);
			free($1);
		}
			  | TRUE
		{
			bool val = true;
			$$ = createConstantAttribute(BOOL_t,&val);
		}
			  | FALSE
		{
			bool val = false;
			$$ = createConstantAttribute(BOOL_t,&val);
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
	//  fprintf( stderr, "%s\t%d\t%s\t%s\n", "Error found in Line ", linenum, "next token: ", yytext );
}


