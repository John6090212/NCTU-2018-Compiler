#include<string.h>
#include<stdlib.h>
#include<stdio.h>
#include"symtable.h"

int initSymTableList(struct SymTableList *list)
{
	list->head = NULL;
	list->tail = NULL;
	list->global = NULL;
	list->reference = 1;
	return 0;
}
int destroySymTableList(struct SymTableList *list)
{
	list->reference -= 1;//derefence
	if(list->reference>0)return -1;
	while(list->head!=NULL)
	{
		//kill head node
		list->head = deleteSymTable(list->head);//return new head
	}
	return 0;
}
struct SymTable* deleteSymTable(struct SymTable* target)
{
	struct SymTable *next;
	if(target==NULL)
		next = NULL;
	else
	{
		target->reference -= 1;//dereference
		if(target->reference>0)
			return NULL;
		next = target->next;
		while(target->head!=NULL)
		{
			target->head = deleteTableNode(target->head);
		}
	}
	if(next!=NULL)next->prev = NULL;
	return next;
}
int AddSymTable(struct SymTableList* list)//enter a new scope
{
	if(list->head == NULL)
	{
		struct SymTable *newTable = (struct SymTable*)malloc(sizeof(struct SymTable));
		newTable->head = NULL;
		newTable->tail = NULL;
		newTable->next = NULL;
		newTable->prev = NULL;
		list->head = newTable;
		list->tail = list->head;
		list->global = list->head;
		newTable->reference = 1;
	}
	else
	{
		struct SymTable *newTable = (struct SymTable*)malloc(sizeof(struct SymTable));
		newTable->head = NULL;
		newTable->tail = NULL;
		newTable->next = NULL;
		newTable->prev = list->tail;
		list->tail->next = newTable;
		list->tail = newTable;
		newTable->reference = 1;
	}
	return 0;
}
int deleteLastSymTable(struct SymTableList* list)//leave scope
{
	struct SymTable *temp = list->tail;
	if(temp==NULL)
		return -1;
	temp->reference -= 1;//derefence
	if(temp->reference>0)
		return -1;
	if(list->head!=list->tail)
	{
		temp->prev->next = NULL;
		list->tail = temp->prev;
	}
	else
	{
		list->tail = NULL;
		list->head = NULL;
	}
	deleteSymTable(temp);
	return 0;
}
int insertTableNode(struct SymTable *table,struct SymTableNode* newNode)
{
	if(table->tail==NULL)
	{
		table->head = newNode;
		table->tail = newNode;
	}
	else
	{
		table->tail->next = newNode;
		table->tail = newNode;
	}
	newNode->reference += 1;
	return 0;
}
struct SymTableNode* deleteTableNode(struct SymTableNode* target)//return next node
{
	struct SymTableNode *next;
	if(target==NULL)
		next = NULL;
	else
	{
		target->reference -= 1;//defreference
		if(target->reference>0)
			return NULL;
		next = target->next;
		killExtType(target->type);
		if(target->attr!=NULL)
			killAttribute(target->attr);
		free(target);
	}
	return next;
}



struct SymTableNode* createVariableNode(const char* name,int level,struct ExtType* type)
{
	struct SymTableNode *newNode = (struct SymTableNode*)malloc(sizeof(struct SymTableNode));
	//set node
	strncpy(newNode->name,name,32);
	newNode->kind = VARIABLE_t;
	newNode->level = level;
	/**/
	newNode->type = type;
	newNode->type->reference += 1;
	/**/
	newNode->attr = NULL;
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;
}
struct SymTableNode* createFunctionNode(const char* name,int level,struct ExtType* type,struct Attribute* attr)
{
	struct SymTableNode *newNode = (struct SymTableNode*)malloc(sizeof(struct SymTableNode));
	//set node
	strncpy(newNode->name,name,32);
	newNode->kind = FUNCTION_t;
	newNode->level = level;
	/**/
	newNode->type = type;
	newNode->type->reference += 1;
	/**/
	newNode->attr = attr;
	if(attr!=NULL)
		newNode->attr->reference += 1;
	/**/
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;

}
struct SymTableNode* createConstNode(const char* name,int level,struct ExtType* type,struct Attribute* attr)
{
	struct SymTableNode *newNode = (struct SymTableNode*)malloc(sizeof(struct SymTableNode));
	//set node
	strncpy(newNode->name,name,32);
	newNode->kind = CONSTANT_t;
	newNode->level = level;
	/**/
	newNode->type = type;
	newNode->type->reference += 1;
	/**/
	newNode->attr = attr;
	if(attr!=NULL)
		newNode->attr->reference += 1;
	/**/
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;
}
struct SymTableNode* createParameterNode(const char* name,int level,struct ExtType* type)
{
	struct SymTableNode *newNode = (struct SymTableNode*)malloc(sizeof(struct SymTableNode));
	//set node
	strncpy(newNode->name,name,32);
	newNode->kind = PARAMETER_t;
	newNode->level = level;
	/**/
	newNode->type = type;
	newNode->type->reference+=1;
	/**/
	newNode->attr = NULL;
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;
}
struct Attribute* createFunctionAttribute(struct FuncAttrNode* list)
{
	int num = 0;
	struct Attribute *newAttr = (struct Attribute*)malloc(sizeof(struct Attribute));
	newAttr->constVal = NULL;
	newAttr->funcParam = (struct FuncAttr*)malloc(sizeof(struct FuncAttr));
	newAttr->funcParam->reference = 1;
	/**/
	newAttr->funcParam->head = list;
	newAttr->funcParam->head->reference += 1;
	/**/
	while(list!=NULL)
	{
		list = list->next;
		++num;
	}
	newAttr->funcParam->paramNum = num;
	newAttr->reference = 0;
	return newAttr;
}
struct Attribute* createConstantAttribute(BTYPE type,void* value)
{
	struct Attribute *newAttr = (struct Attribute*)malloc(sizeof(struct Attribute));
	struct ConstAttr *newConstAttr = (struct ConstAttr*)malloc(sizeof(struct ConstAttr));
	newAttr->funcParam = NULL;
	newAttr->constVal = newConstAttr;
	newConstAttr->reference = 1;
	newConstAttr->hasMinus = false;
	newConstAttr->type = type;
	switch(type)
	{
		case INT_t:
			newConstAttr->value.integerVal = *(int*)value;
			if(*(int*)value < 0)
				newConstAttr->hasMinus = true;
			break;
		case FLOAT_t:
			newConstAttr->value.floatVal = *(float*)value;
			if(*(float*)value < 0.0)
				newConstAttr->hasMinus = true;
			break;
		case DOUBLE_t:
			newConstAttr->value.doubleVal = *(double*)value;
			if(*(double*)value < 0.0)
				newConstAttr->hasMinus = true;
			break;
		case BOOL_t:
			newConstAttr->value.boolVal = *(bool*)value;
			break;
		case STRING_t:
			newConstAttr->value.stringVal = strdup((char*)value);
			break;
		default:
			break;
	}
	newAttr->reference = 0;
	return newAttr;
}
struct FuncAttrNode* deleteFuncAttrNode(struct FuncAttrNode* target)
{
	struct FuncAttrNode *next;
	if(target==NULL)
		next=NULL;
	else
	{
		target->reference -= 1;
		if(target->reference>0)
			return NULL;
		next = target->next;
		killExtType(target->value);
		free(target->name);
		free(target);
	}
	return next;
}
int killAttribute(struct Attribute* target)
{
	target->reference -= 1;
	if(target->reference>0)
		return -1;
	if(target->constVal!=NULL)
	{
		target->constVal->reference -= 1;
		if(target->constVal->reference>0)
			return -1;
		if(target->constVal->type==STRING_t)
			free(target->constVal->value.stringVal);
		free(target->constVal);
	}
	if(target->funcParam!=NULL)
	{
		target->funcParam->reference -= 1;
		if(target->funcParam->reference>0)
			return -1;
		target->funcParam->head = deleteFuncAttrNode(target->funcParam->head);
		free(target->funcParam);
	}
	free(target);
	return 0;
}
struct FuncAttrNode* createFuncAttrNode(struct ExtType* type,const char* name)
{
	struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
	/*reference*/
	newNode->value = type;
	type->reference += 1;
	/*         */
	newNode->name = strdup(name);
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;
}
int connectFuncAttrNode(struct FuncAttrNode* head, struct FuncAttrNode* newNode)//connect node to tail of function attribute list
{
	if(head==NULL || newNode==NULL || head==newNode)
		return -1;
	struct FuncAttrNode *temp = head;
	while(temp->next!=NULL)
	{
		temp = temp->next;
	}
	temp->next = newNode;
	newNode->reference += 1;
	return 0;
}
struct ExtType* createExtType(BTYPE baseType,int intvalue,bool isArray,struct ArrayDimNode* dimArray,int *intarrayvalue,int intarraysize,bool has_initialvalue)
{
	int dimNum = 0;
	struct ArrayDimNode *temp = dimArray;
	struct ExtType *newExtType = (struct ExtType*)malloc(sizeof(struct ExtType));
	newExtType->baseType = baseType;
	newExtType->intvalue = intvalue;
	//printf("intvalue finish\n");
	newExtType->isArray = isArray;
	/**/
	newExtType->dimArray = dimArray;
	if(dimArray!=NULL)
		dimArray->reference += 1;
	/**/
	newExtType->reference = 0;
	//printf("reference finish\n");
	int arraysize = 1;
	while(temp!=NULL)
	{
		arraysize = arraysize * temp->size;
		++dimNum;
		temp = temp->next;
	}
	newExtType->dim = dimNum;
	//printf("dim finish\n");
	
	if(dimNum > 0 && intarrayvalue != NULL){
		int *intvalueofarray = (int*)malloc(sizeof(int) * arraysize);
		int i;
		for(i = 0; i < arraysize; i++){
			if(i < intarraysize){
				intvalueofarray[i] = intarrayvalue[i];
			}
			else{
				intvalueofarray[i] = 0;
			}
		}
		newExtType->intarraysize = arraysize;
		newExtType->intarrayvalue = intvalueofarray; 
	}
	else{
		newExtType->intarraysize = 0;
		newExtType->intarrayvalue = NULL;
	}
	
	//printf("int array finish\n");
	newExtType->dim_smaller = false;
	newExtType->dim_count = dimNum; 
	newExtType->has_initialvalue = has_initialvalue;
	
	return newExtType;
}



int killExtType(struct ExtType* target)
{
	if(target==NULL)
		return -1;
	target->reference -= 1;
	if(target->reference>0)
		return -1;
	if(target->isArray)
	{
		while(target->dimArray!=NULL)
		{
			target->dimArray = deleteArrayDimNode(target->dimArray);
		}
		free(target->intarrayvalue);
	}
	return 0;
}
struct ArrayDimNode* createArrayDimNode(int size)
{
	struct ArrayDimNode *newNode = (struct ArrayDimNode*)malloc(sizeof(struct ArrayDimNode));
	newNode->size = size;
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;
}
int connectArrayDimNode(struct ArrayDimNode* head,struct ArrayDimNode* newNode)//connect dimension node to tail of list
{
	if(head==NULL || newNode==NULL || head==newNode)
		return -1;
	struct ArrayDimNode *temp = head;
	while(temp->next!=NULL)
	{
		temp = temp->next;
	}
	/**/
	temp->next = newNode;
	newNode->reference += 1;
	/**/
	return 0;
}
struct ArrayDimNode* deleteArrayDimNode(struct ArrayDimNode* target)
{
	struct ArrayDimNode *next;
	if(target==NULL)
		next = NULL;
	else
	{
		target->reference -= 1;
		if(target->reference>0)
			return NULL;
		next = target->next;
		free(target);
	}
	return next;
}


struct SymTableNode* findFuncDeclaration(struct SymTable* table,const char* name)
{
	struct SymTableNode *temp = table->head;
	while(temp!=NULL)
	{
		if(temp->kind == FUNCTION_t)
		{
			if(strncmp(temp->name,name,32)==0)
				return temp;
		}
		temp = temp->next;
	}
	return NULL;
}

int printSymTable(struct SymTable* table)
{
	struct SymTableNode *entry;
	struct ArrayDimNode *dimNode;
	struct Attribute *attr;
	struct FuncAttrNode *funcAttrNode;
	char strBuffer[32];
	if(table==NULL)return -1;
	if(table->head==NULL)return 1;//no entry to output
	printf("=======================================================================================\n");
	// Name [29 blanks] Kind [7 blanks] Level [7 blank] Type [15 blanks] Attribute [15 blanks]
	printf("Name                             Kind       Level       Type               Attribute               \n");
	printf("---------------------------------------------------------------------------------------\n");
	entry = table->head;
	while(entry!=NULL)
	{
		//name
		printf("%-32s ",entry->name);
		//kind
		switch(entry->kind)
		{
			case VARIABLE_t:
				printf("%-11s","variable");
				break;
			case CONSTANT_t:
				printf("%-11s","constant");
				break;
			case FUNCTION_t:
				printf("%-11s","function");
				break;
			case PARAMETER_t:
				printf("%-11s","parameter");
				break;
			default:
				printf("%-11s","unknown");
				break;
		}
		//level
		if(entry->level==0)
			printf("%-12s","0(global) ");
		else
		{
			sprintf(strBuffer,"%d(local)  ",entry->level);
			printf("%-12s",strBuffer);
		}
		//type
		printType(entry->type);
		//attribute
		attr = entry->attr;
		if(attr!=NULL)
		{
			if(attr->constVal!=NULL)
			{
				printConstAttribute(attr->constVal);
			}
			if(attr->funcParam!=NULL)
			{
				printParamAttribute(attr->funcParam);
			}
		}
		entry = entry->next;
		printf("\n");
	}
	printf("======================================================================================\n");
}
int printType(struct ExtType* extType)
{
	struct ArrayDimNode *dimNode;
	char strBuffer[20];
	char strTemp[20];
	if(extType == NULL)
		return -1;
	memset(strBuffer,0,20*sizeof(char));
	switch(extType->baseType)
	{
		case INT_t:
			strncpy(strBuffer,"int",3);
			break;
		case FLOAT_t:
			strncpy(strBuffer,"float",5);
			break;
		case DOUBLE_t:
			strncpy(strBuffer,"double",6);
			break;
		case BOOL_t:
			strncpy(strBuffer,"bool",4);
			break;
		case STRING_t:
			strncpy(strBuffer,"string",6);
			break;
		case VOID_t:
			strncpy(strBuffer,"void",4);
			break;
		default:
			strncpy(strBuffer,"unknown",7);
			break;
	}
	if(extType->isArray)
	{
		dimNode = extType->dimArray;
		while(dimNode!=NULL)
		{
			memset(strTemp,0,20*sizeof(char));
			sprintf(strTemp,"[%d]",dimNode->size);
			if(strlen(strBuffer)+strlen(strTemp)<20)
				strcat(strBuffer,strTemp);
			else
			{
				strBuffer[16]='.';
				strBuffer[17]='.';
				strBuffer[18]='.';
			}
			dimNode = dimNode->next;
		}
	}
	printf("%-19s",strBuffer);
	return 0;
}
int printConstAttribute(struct ConstAttr* constAttr)
{
	switch(constAttr->type)
	{
		case INT_t:
			printf("%d",constAttr->value.integerVal);
			break;
		case FLOAT_t:
			printf("%f",constAttr->value.floatVal);
			break;
		case DOUBLE_t:
			printf("%lf",constAttr->value.doubleVal);
			break;
		case BOOL_t:
			if(constAttr->value.boolVal)
				printf("true");
			else
				printf("false");
			break;
		case STRING_t:
			printf("%s",constAttr->value.stringVal);
			break;
		default:
			printf("__ERROR__");
			break;
	}
	return 0;
}
int printParamAttribute(struct FuncAttr* funcAttr)
{
	struct FuncAttrNode* attrNode = funcAttr->head;
	struct ArrayDimNode* dimNode;
	if(attrNode!=NULL)
	{
		switch(attrNode->value->baseType)
		{
			case INT_t:
				printf("int");
				break;
			case FLOAT_t:
				printf("float");
				break;
			case DOUBLE_t:
				printf("double");
				break;
			case BOOL_t:
				printf("bool");
				break;
			case STRING_t:
				printf("string");
				break;
			case VOID_t:
				printf("void");
				break;
			default:
				printf("unknown");
				break;
		}
		if(attrNode->value->isArray)
		{
			dimNode = attrNode->value->dimArray;
			while(dimNode!=NULL)
			{
				printf("[%d]",dimNode->size);
				dimNode = dimNode->next;
			}
		}
		attrNode = attrNode->next;
		while(attrNode!=NULL)
		{
			switch(attrNode->value->baseType)
			{
				case INT_t:
					printf(",int");
					break;
				case FLOAT_t:
					printf(",float");
					break;
				case DOUBLE_t:
					printf(",double");
					break;
				case BOOL_t:
					printf(",bool");
					break;
				case STRING_t:
					printf(",string");
					break;
				case VOID_t:
					printf(",void");
					break;
				default:
					printf(",unknown");
					break;
			}
			if(attrNode->value->isArray)
			{
				dimNode = attrNode->value->dimArray;
				while(dimNode!=NULL)
				{
					printf("[%d]",dimNode->size);
					dimNode = dimNode->next;
				}
			}
			attrNode = attrNode->next;
		}
	}
	return 0;
}
struct VariableList* createVariableList(struct Variable* head)
{	
	struct VariableList *list;
	if(head==NULL)
		list = NULL;
	else
	{
		list = (struct VariableList*)malloc(sizeof(struct VariableList));
		struct Variable* temp = head;
		while(temp->next!=NULL)
		{
			temp = temp->next;
		}
		/**/
		list->head = head;
		head->reference += 1;
		/**/
		list->tail = temp;
		if(head!=temp)
			temp->reference += 1;
		/**/
		list->reference = 0;
	}
	return list;
}
int deleteVariableList(struct VariableList* list)
{
	list->reference -= 1;
	if(list->reference>0)
		return -1;
	if(list->head!=NULL)
	{
		/**/
		//list->head = NULL
		list->head->reference -= 1;
		/**/
		if(list->head!=list->tail)
		{
			//list->tail = NULL
			list->tail->reference -= 1;
		}
		/**/
		while(list->head!=NULL)
		{
			list->head=deleteVariable(list->head);
		}
	}
	return 0;
}
int connectVariableList(struct VariableList* list,struct Variable* node)
{
	if(list==NULL||node==NULL)
		return -1;
	if(node->next!=NULL)
		return -2;
	if(list->tail!=list->head)
		list->tail->reference -= 1;
	/**/
	list->tail->next = node;
	list->tail->next->reference += 1;
	list->tail = node;
	list->tail->reference += 1;
	/**/
	return 0;
}
struct Variable* createVariable(const char* name,struct ExtType* type,struct VariableList* array_initial)
{
	struct Variable* variable = (struct Variable*)malloc(sizeof(struct Variable));
	variable->name = strdup(name);
	/**/
	variable->type = type;
	if(type != NULL){
		type->reference += 1;
	}
	/**/
	variable->next = NULL;
	variable->reference = 0;
	variable->array_initial = array_initial;
	variable->initial_success = true;
	return variable;
}
struct Variable* deleteVariable(struct Variable* target)
{
	struct Variable* next;
	if(target == NULL)
		next = NULL;
	else
	{
		target->reference -= 1;
		if(target->reference>0)
			return NULL;
		free(target->name);
		killExtType(target->type);
		next = target->next;
		free(target);
	}
	return next;
}

//new function
struct FuncDeclNode* insertFuncDeclList(struct FuncDeclNode* decllist,struct SymTableNode* newNode){
	struct FuncDeclNode* newdecl = (struct FuncDeclNode*)malloc(sizeof(struct FuncDeclNode));
	newdecl->reference = newNode->reference;
	strncpy(newdecl->name,newNode->name,32);
	newdecl->kind = newNode->kind;
	newdecl->level = newNode->level; 
	newdecl->type = newNode->type;
	newdecl->attr = newNode->attr;
	newdecl->next = NULL;
	newdecl->has_defined = false;
	if(decllist == NULL){
		decllist = newdecl;
		return decllist;
	}
	else{
		struct FuncDeclNode* current = decllist;
		while(current->next != NULL){
			current = current->next;
		}
		current->next = newdecl;
		return decllist;
	}
}
struct FuncDeclNode* searchFuncDeclList(struct FuncDeclNode* decllist,const char* name){
	struct FuncDeclNode *temp = decllist;
	while(temp != NULL)
	{
		if(strncmp(temp->name,name,32)==0){
			return temp;
		}
		temp = temp->next;
	}
	return NULL;
}
void checkFuncDeclList(struct FuncDeclNode* decllist, int linenum){
	struct FuncDeclNode *temp = decllist;

	while(temp != NULL){
		if(temp->has_defined == 0){
			printf("##########Error at Line #%d: Function \"%s\" declares but never defined.##########\n",linenum,temp->name);
		}
		if(temp->next != NULL){
			temp = temp->next;
		}
		else{
			break;
		}
	}
	return;
}

bool compareFuncAttrNode(struct FuncAttrNode* node1,struct FuncAttrNode* node2){
	struct FuncAttrNode* current1 = node1;
	struct FuncAttrNode* current2 = node2;
	while(current1 != NULL || current2 != NULL){
		if(current1 == NULL){
			return false;
		}
		else if(current2 == NULL){
			return false;
		}
		else{
			if(strcmp(current1->name,current2->name) != 0 || !compareExtType(current1->value,current2->value)){
				return false;
			}
		}
		current1 = current1->next;
		current2 = current2->next;
	}
	return true;
}

bool compareExtType(struct ExtType* type1,struct ExtType* type2){
	if(type1->baseType != type2->baseType || type1->isArray != type2->isArray || type1->dim != type2->dim){
		return false;
	}
	else if(type1->isArray == false){
		return true;
	}
	else{
		struct ArrayDimNode* current1 = type1->dimArray;
		struct ArrayDimNode* current2 = type2->dimArray;
		while(current1 != NULL && current2 != NULL){
			if(current1->size != current2->size){
				return false;
			}
			current1 = current1->next;
			current2 = current2->next;
		}
		return true;
	}
}

struct SymTableNode* findSymTableNode(struct SymTable* table,const char* name)
{
	struct SymTableNode *temp = table->head;
	while(temp!=NULL)
	{
		if(strncmp(temp->name,name,32)==0)
			return temp;
			
		temp = temp->next;
	}
	return NULL;
}

bool findFuncAttrNode(struct FuncAttrNode* head,const char* name){
	struct FuncAttrNode *temp = head;
	while(temp != NULL){
		if(strncmp(temp->name,name,32) == 0){
			return true;
		}
		temp = temp->next;
	}
	return false;
}

struct ExtType* unarySUB_OPcheck(struct ExtType* operand,int linenum){
	struct ExtType* temp;
	if(operand == NULL){
		printf("##########Error at Line #%d: Operand of unary minus must be int, float or double type.##########\n",linenum);
		return NULL;
	}
	else if(operand->baseType != INT_t && operand->baseType != FLOAT_t && operand->baseType != DOUBLE_t){
		printf("##########Error at Line #%d: Operand of unary minus must be int, float or double type.##########\n",linenum);
		return NULL;
	}
	else if(operand->isArray){
		if(operand->dim_smaller){
			printf("##########Error at Line #%d: Array can't do unary minus operation.##########\n",linenum);
			return NULL;
		}
		else{
			temp = createExtType(operand->baseType,0,false,NULL,NULL,0,false);
			return temp;
		}
	}
	else{
		temp = operand;
		temp->intvalue = -temp->intvalue;
		return temp;
	}
}

struct ExtType* MUL_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum){
	struct ExtType* temp;
	if(operand1 == NULL){
		if(operand2 == NULL){
			printf("##########Error at Line #%d: The former operand and the latter operand of multiplication must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of multiplication must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->isArray){
			if(operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do multiplication operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of multiplication must be int, float or double type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The former operand of multiplication must be int, float or double type.##########\n",linenum);
				return NULL;
			}
		}
		else{	
			printf("##########Error at Line #%d: The former operand of multiplication must be int, float or double type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand2 == NULL){
		if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of multiplication must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand1->isArray){
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do multiplication operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of multiplication must be int, float or double type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The latter operand of multiplication must be int, float or double type.##########\n",linenum);
				return NULL;
			}
		}
		else{
			printf("##########Error at Line #%d: The latter operand of multiplication must be int, float or double type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t){
		if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of multiplication must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		printf("##########Error at Line #%d: The former operand of multiplication must be int, float or double type.##########\n",linenum);
		return NULL;
	}
	else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
		printf("##########Error at Line #%d: The latter operand of multiplication must be int, float or double type.##########\n",linenum);
		return NULL;
	}
	else if(operand1->isArray){
		if(operand2->isArray){
			if(operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand and the latter operand can't do multiplication operation.##########\n",linenum);
				return NULL;
			}
			else if(operand1->dim_smaller && !operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do multiplication operation.##########\n",linenum);
				return NULL;
			}	
			else if(!operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do multiplication operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
				return temp;
			}
		}
		else{
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do multiplication operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
				return temp;
			}
		}
	}
	else if(operand2->isArray){
		if(operand2->dim_smaller){
			printf("##########Error at Line #%d: Array in the latter operand can't do multiplication operation.##########\n",linenum);
			return NULL;
		}
		else{
			temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
			return temp;
		}
	}
	else{
		temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
		return temp;
	}
}

BTYPE typecoercion(BTYPE first,BTYPE second){
	if(first == DOUBLE_t || second == DOUBLE_t){
		return DOUBLE_t;
	}
	else if(first == FLOAT_t || second == FLOAT_t){
		return FLOAT_t;
	}
	else{
		return INT_t;
	}
}

struct ExtType* DIV_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum){
	struct ExtType* temp;
	if(operand1 == NULL){
		if(operand2 == NULL){
			printf("##########Error at Line #%d: The former operand and the latter operand of division must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of division must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->isArray){
			if(operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do division operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of division must be int, float or double type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The former operand of division must be int, float or double type.##########\n",linenum);
				return NULL;
			}
		}
		else{	
			printf("##########Error at Line #%d: The former operand of division must be int, float or double type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand2 == NULL){
		if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of division must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand1->isArray){
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do division operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of division must be int, float or double type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The latter operand of division must be int, float or double type.##########\n",linenum);
				return NULL;
			}
		}
		else{
			printf("##########Error at Line #%d: The latter operand of division must be int, float or double type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t){
		if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of division must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		printf("##########Error at Line #%d: The former operand of division must be int, float or double type.##########\n",linenum);
		return NULL;
	}
	else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
		printf("##########Error at Line #%d: The latter operand of division must be int, float or double type.##########\n",linenum);
		return NULL;
	}
	else if(operand1->isArray){
		if(operand2->isArray){
			if(operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand and the latter operand can't do division operation.##########\n",linenum);
				return NULL;
			}
			else if(operand1->dim_smaller && !operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do division operation.##########\n",linenum);
				return NULL;
			}	
			else if(!operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do division operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
				return temp;
			}
		}
		else{
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do division operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
				return temp;
			}
		}
	}
	else if(operand2->isArray){
		if(operand2->dim_smaller){
			printf("##########Error at Line #%d: Array in the latter operand can't do division operation.##########\n",linenum);
			return NULL;
		}
		else{
			temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
			return temp;
		}
	}
	else{
		temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
		return temp;
	}
}

struct ExtType* MOD_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum){
	struct ExtType* temp;
	if(operand1 == NULL){
		if(operand2 == NULL){
			printf("##########Error at Line #%d: The former operand and the latter operand of modulation must be int type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->baseType != INT_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of modulation must be int type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->isArray){
			if(operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do modulation operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of modulation must be int type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The former operand of modulation must be int type.##########\n",linenum);
				return NULL;
			}
		}
		else{	
			printf("##########Error at Line #%d: The former operand of modulation must be int type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand2 == NULL){
		if(operand1->baseType != INT_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of modulation must be int type.##########\n",linenum);
			return NULL;
		}
		else if(operand1->isArray){
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do modulation operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of modulation must be int type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The latter operand of modulation must be int type.##########\n",linenum);
				return NULL;
			}
		}
		else{
			printf("##########Error at Line #%d: The latter operand of modulation must be int type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand1->baseType != INT_t){
		if(operand2->baseType != INT_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of modulation must be int type.##########\n",linenum);
			return NULL;
		}
		printf("##########Error at Line #%d: The former operand of modulation must be int type.##########\n",linenum);
		return NULL;
	}
	else if(operand2->baseType != INT_t){
		printf("##########Error at Line #%d: The latter operand of modulation must be int type.##########\n",linenum);
		return NULL;
	}
	else if(operand1->isArray){
		if(operand2->isArray){
			if(operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand and the latter operand can't do modulation operation.##########\n",linenum);
				return NULL;
			}
			else if(operand1->dim_smaller && !operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do modulation operation.##########\n",linenum);
				return NULL;
			}	
			else if(!operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do modulation operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(INT_t,0,false,NULL,NULL,0,false);
				return temp;
			}
		}
		else{
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do modulation operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(INT_t,0,false,NULL,NULL,0,false);
				return temp;
			}
		}
	}
	else if(operand2->isArray){
		if(operand2->dim_smaller){
			printf("##########Error at Line #%d: Array in the latter operand can't do modulation operation.##########\n",linenum);
			return NULL;
		}
		else{
			temp = createExtType(INT_t,0,false,NULL,NULL,0,false);
			return temp;
		}
	}
	else{
		temp = createExtType(INT_t,0,false,NULL,NULL,0,false);
		return temp;
	}
}

struct ExtType* ADD_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum){
	struct ExtType* temp;
	if(operand1 == NULL){
		if(operand2 == NULL){
			printf("##########Error at Line #%d: The former operand and the latter operand of addition must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of addition must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->isArray){
			if(operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do addition operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of addition must be int, float or double type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The former operand of addition must be int, float or double type.##########\n",linenum);
				return NULL;
			}
		}
		else{	
			printf("##########Error at Line #%d: The former operand of addition must be int, float or double type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand2 == NULL){
		if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of addition must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand1->isArray){
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do addition operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of addition must be int, float or double type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The latter operand of addition must be int, float or double type.##########\n",linenum);
				return NULL;
			}
		}
		else{
			printf("##########Error at Line #%d: The latter operand of addition must be int, float or double type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t){
		if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of addition must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		printf("##########Error at Line #%d: The former operand of addition must be int, float or double type.##########\n",linenum);
		return NULL;
	}
	else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
		printf("##########Error at Line #%d: The latter operand of addition must be int, float or double type.##########\n",linenum);
		return NULL;
	}
	else if(operand1->isArray){
		if(operand2->isArray){
			if(operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand and the latter operand can't do addition operation.##########\n",linenum);
				return NULL;
			}
			else if(operand1->dim_smaller && !operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do addition operation.##########\n",linenum);
				return NULL;
			}	
			else if(!operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do addition operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
				return temp;
			}
		}
		else{
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do addition operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
				return temp;
			}
		}
	}
	else if(operand2->isArray){
		if(operand2->dim_smaller){
			printf("##########Error at Line #%d: Array in the latter operand can't do addition operation.##########\n",linenum);
			return NULL;
		}
		else{
			temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
			return temp;
		}
	}
	else{
		temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
		return temp;
	}
}

struct ExtType* SUB_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum){
	struct ExtType* temp;
	if(operand1 == NULL){
		if(operand2 == NULL){
			printf("##########Error at Line #%d: The former operand and the latter operand of subtraction must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of subtraction must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->isArray){
			if(operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do subtraction operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of subtraction must be int, float or double type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The former operand of subtraction must be int, float or double type.##########\n",linenum);
				return NULL;
			}
		}
		else{	
			printf("##########Error at Line #%d: The former operand of subtraction must be int, float or double type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand2 == NULL){
		if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of subtraction must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand1->isArray){
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do subtraction operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of subtraction must be int, float or double type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The latter operand of subtraction must be int, float or double type.##########\n",linenum);
				return NULL;
			}
		}
		else{
			printf("##########Error at Line #%d: The latter operand of subtraction must be int, float or double type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t){
		if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of subtraction must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		printf("##########Error at Line #%d: The former operand of subtraction must be int, float or double type.##########\n",linenum);
		return NULL;
	}
	else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
		printf("##########Error at Line #%d: The latter operand of subtraction must be int, float or double type.##########\n",linenum);
		return NULL;
	}
	else if(operand1->isArray){
		if(operand2->isArray){
			if(operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand and the latter operand can't do subtraction operation.##########\n",linenum);
				return NULL;
			}
			else if(operand1->dim_smaller && !operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do subtraction operation.##########\n",linenum);
				return NULL;
			}	
			else if(!operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do subtraction operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
				return temp;
			}
		}
		else{
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do subtraction operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
				return temp;
			}
		}
	}
	else if(operand2->isArray){
		if(operand2->dim_smaller){
			printf("##########Error at Line #%d: Array in the latter operand can't do subtraction operation.##########\n",linenum);
			return NULL;
		}
		else{
			temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
			return temp;
		}
	}
	else{
		temp = createExtType(typecoercion(operand1->baseType,operand2->baseType),0,false,NULL,NULL,0,false);
		return temp;
	}
}

struct ExtType* rel_op4check(struct ExtType* operand1,struct ExtType* operand2,REL_OP rel_op,int linenum){
	struct ExtType* temp;
	char *str;
	if(rel_op == LT_t)
		str = "<";
	else if(rel_op == LE_t)
		str = "<=";
	else if(rel_op == GE_t)
		str = ">=";
	else if(rel_op == GT_t)
		str = ">";
		
	if(operand1 == NULL){
		if(operand2 == NULL){
			printf("##########Error at Line #%d: The former operand and the latter operand of %s must be int, float or double type.##########\n",linenum,str);
			return NULL;
		}
		else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of %s must be int, float or double type.##########\n",linenum,str);
			return NULL;
		}
		else if(operand2->isArray){
			if(operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do %s operation.##########\n",linenum,str);
				printf("##########Error at Line #%d: The former operand and the latter operand of %s must be int, float or double type.##########\n",linenum,str);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The former operand of %s must be int, float or double type.##########\n",linenum,str);
				return NULL;
			}
		}
		else{	
			printf("##########Error at Line #%d: The former operand of %s must be int, float or double type.##########\n",linenum,str);
			return NULL;
		}	
	}
	else if(operand2 == NULL){
		if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of subtraction must be int, float or double type.##########\n",linenum);
			return NULL;
		}
		else if(operand1->isArray){
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand and the latter operand can't do %s operation.##########\n",linenum,str);
				printf("##########Error at Line #%d: The former operand and the latter operand of %s must be int, float or double type.##########\n",linenum,str);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The latter operand of %s must be int, float or double type.##########\n",linenum,str);
				return NULL;
			}
		}
		else{
			printf("##########Error at Line #%d: The latter operand of %s must be int, float or double type.##########\n",linenum,str);
			return NULL;
		}	
	}
	else if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t){
		if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of %s must be int, float or double type.##########\n",linenum,str);
			return NULL;
		}
		printf("##########Error at Line #%d: The former operand of %s must be int, float or double type.##########\n",linenum,str);
		return NULL;
	}
	else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t){
		printf("##########Error at Line #%d: The latter operand of %s must be int, float or double type.##########\n",linenum,str);
		return NULL;
	}
	else if(operand1->isArray){
		if(operand2->isArray){
			if(operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand and the latter operand can't do %s operation.##########\n",linenum,str);
				return NULL;
			}
			else if(operand1->dim_smaller && !operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do %s operation.##########\n",linenum,str);
				return NULL;
			}	
			else if(!operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do %s operation.##########\n",linenum,str);
				return NULL;
			}
			else{
				temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
				return temp;
			}
		}
		else{
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do %s operation.##########\n",linenum,str);
				return NULL;
			}
			else{
				temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
				return temp;
			}
		}
	}
	else if(operand2->isArray){
		if(operand2->dim_smaller){
			printf("##########Error at Line #%d: Array in the latter operand can't do %s operation.##########\n",linenum,str);
			return NULL;
		}
		else{
			temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
			return temp;
		}
	}
	else{
		temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
		return temp;
	}
}

struct ExtType* rel_op2check(struct ExtType* operand1,struct ExtType* operand2,REL_OP rel_op,int linenum){
	struct ExtType* temp;
	char *str;
	if(rel_op == EQ_t)
		str = "==";
	else
		str = "!=";
		
	if(operand1 == NULL){
		if(operand2 == NULL){
			printf("##########Error at Line #%d: The former operand and the latter operand of %s must be int, float, double or bool type.##########\n",linenum,str);
			return NULL;
		}
		else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t && operand2->baseType != BOOL_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of %s must be int, float, double or bool type.##########\n",linenum,str);
			return NULL;
		}
		else if(operand2->isArray){
			if(operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do %s operation.##########\n",linenum,str);
				printf("##########Error at Line #%d: The former operand and the latter operand of %s must be int, float, double or bool type.##########\n",linenum,str);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The former operand of %s must be int, float, double or bool type.##########\n",linenum,str);
				return NULL;
			}
		}
		else{	
			printf("##########Error at Line #%d: The former operand of %s must be int, float, double or bool type.##########\n",linenum,str);
			return NULL;
		}	
	}
	else if(operand2 == NULL){
		if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t && operand1->baseType != BOOL_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of subtraction must be int, float, double or bool type.##########\n",linenum);
			return NULL;
		}
		else if(operand1->isArray){
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand and the latter operand can't do %s operation.##########\n",linenum,str);
				printf("##########Error at Line #%d: The former operand and the latter operand of %s must be int, float, double or bool type.##########\n",linenum,str);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The latter operand of %s must be int, float, double or bool type.##########\n",linenum,str);
				return NULL;
			}
		}
		else{
			printf("##########Error at Line #%d: The latter operand of %s must be int, float, double or bool type.##########\n",linenum,str);
			return NULL;
		}	
	}
	else if(operand1->baseType != INT_t && operand1->baseType != FLOAT_t && operand1->baseType != DOUBLE_t && operand1->baseType != BOOL_t){
		if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t && operand2->baseType != BOOL_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of %s must be int, float, double or bool type.##########\n",linenum,str);
			return NULL;
		}
		printf("##########Error at Line #%d: The former operand of %s must be int, float, double or bool type.##########\n",linenum,str);
		return NULL;
	}
	else if(operand2->baseType != INT_t && operand2->baseType != FLOAT_t && operand2->baseType != DOUBLE_t && operand2->baseType != BOOL_t){
		printf("##########Error at Line #%d: The latter operand of %s must be int, float, double or bool type.##########\n",linenum,str);
		return NULL;
	}
	else if(operand1->isArray){
		if(operand2->isArray){
			if(operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand and the latter operand can't do %s operation.##########\n",linenum,str);
				return NULL;
			}
			else if(operand1->dim_smaller && !operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do %s operation.##########\n",linenum,str);
				return NULL;
			}	
			else if(!operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do %s operation.##########\n",linenum,str);
				return NULL;
			}
			else{
				temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
				return temp;
			}
		}
		else{
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do %s operation.##########\n",linenum,str);
				return NULL;
			}
			else{
				temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
				return temp;
			}
		}
	}
	else if(operand2->isArray){
		if(operand2->dim_smaller){
			printf("##########Error at Line #%d: Array in the latter operand can't do %s operation.##########\n",linenum,str);
			return NULL;
		}
		else{
			temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
			return temp;
		}
	}
	else{
		temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
		return temp;
	}
}

struct ExtType* NOT_OPcheck(struct ExtType* operand,int linenum){
	struct ExtType* temp;
	if(operand == NULL){
		printf("##########Error at Line #%d: Operand of ! must be bool type.##########\n",linenum);
		return NULL;
	}
	else if(operand->baseType != BOOL_t){
		printf("##########Error at Line #%d: Operand of ! must be bool type.##########\n",linenum);
		return NULL;
	}
	else if(operand->isArray){
		if(operand->dim_smaller){
			printf("##########Error at Line #%d: Array can't do ! operation.##########\n",linenum);
			return NULL;
		}
		else{
			temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
			return temp;
		}
	}
	else{
		temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
		return temp;
	}
}

struct ExtType* AND_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum){
	struct ExtType* temp;
	if(operand1 == NULL){
		if(operand2 == NULL){
			printf("##########Error at Line #%d: The former operand and the latter operand of && must be bool type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->baseType != BOOL_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of && must be bool type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->isArray){
			if(operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do && operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of && must be bool type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The former operand of && must be bool type.##########\n",linenum);
				return NULL;
			}
		}
		else{	
			printf("##########Error at Line #%d: The former operand of && must be bool type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand2 == NULL){
		if(operand1->baseType != BOOL_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of && must be bool type.##########\n",linenum);
			return NULL;
		}
		else if(operand1->isArray){
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do && operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of && must be bool type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The latter operand of && must be bool type.##########\n",linenum);
				return NULL;
			}
		}
		else{
			printf("##########Error at Line #%d: The latter operand of && must be bool type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand1->baseType != BOOL_t){
		if(operand2->baseType != BOOL_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of && must be bool type.##########\n",linenum);
			return NULL;
		}
		printf("##########Error at Line #%d: The former operand of && must be bool type.##########\n",linenum);
		return NULL;
	}
	else if(operand2->baseType != BOOL_t){
		printf("##########Error at Line #%d: The latter operand of && must be bool type.##########\n",linenum);
		return NULL;
	}
	else if(operand1->isArray){
		if(operand2->isArray){
			if(operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand and the latter operand can't do && operation.##########\n",linenum);
				return NULL;
			}
			else if(operand1->dim_smaller && !operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do && operation.##########\n",linenum);
				return NULL;
			}	
			else if(!operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do && operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
				return temp;
			}
		}
		else{
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do && operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
				return temp;
			}
		}
	}
	else if(operand2->isArray){
		if(operand2->dim_smaller){
			printf("##########Error at Line #%d: Array in the latter operand can't do && operation.##########\n",linenum);
			return NULL;
		}
		else{
			temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
			return temp;
		}
	}
	else{
		temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
		return temp;
	}
}

struct ExtType* OR_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum){
	struct ExtType* temp;
	if(operand1 == NULL){
		if(operand2 == NULL){
			printf("##########Error at Line #%d: The former operand and the latter operand of || must be bool type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->baseType != BOOL_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of || must be bool type.##########\n",linenum);
			return NULL;
		}
		else if(operand2->isArray){
			if(operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do || operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of || must be bool type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The former operand of || must be bool type.##########\n",linenum);
				return NULL;
			}
		}
		else{	
			printf("##########Error at Line #%d: The former operand of || must be bool type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand2 == NULL){
		if(operand1->baseType != BOOL_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of || must be bool type.##########\n",linenum);
			return NULL;
		}
		else if(operand1->isArray){
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do || operation.##########\n",linenum);
				printf("##########Error at Line #%d: The former operand and the latter operand of || must be bool type.##########\n",linenum);
				return NULL;
			}
			else{
				printf("##########Error at Line #%d: The latter operand of || must be bool type.##########\n",linenum);
				return NULL;
			}
		}
		else{
			printf("##########Error at Line #%d: The latter operand of || must be bool type.##########\n",linenum);
			return NULL;
		}	
	}
	else if(operand1->baseType != BOOL_t){
		if(operand2->baseType != BOOL_t){
			printf("##########Error at Line #%d: The former operand and the latter operand of || must be bool type.##########\n",linenum);
			return NULL;
		}
		printf("##########Error at Line #%d: The former operand of || must be bool type.##########\n",linenum);
		return NULL;
	}
	else if(operand2->baseType != BOOL_t){
		printf("##########Error at Line #%d: The latter operand of || must be bool type.##########\n",linenum);
		return NULL;
	}
	else if(operand1->isArray){
		if(operand2->isArray){
			if(operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand and the latter operand can't do || operation.##########\n",linenum);
				return NULL;
			}
			else if(operand1->dim_smaller && !operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do || operation.##########\n",linenum);
				return NULL;
			}	
			else if(!operand1->dim_smaller && operand2->dim_smaller){
				printf("##########Error at Line #%d: Array in the latter operand can't do || operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
				return temp;
			}
		}
		else{
			if(operand1->dim_smaller){
				printf("##########Error at Line #%d: Array in the former operand can't do || operation.##########\n",linenum);
				return NULL;
			}
			else{
				temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
				return temp;
			}
		}
	}
	else if(operand2->isArray){
		if(operand2->dim_smaller){
			printf("##########Error at Line #%d: Array in the latter operand can't do || operation.##########\n",linenum);
			return NULL;
		}
		else{
			temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
			return temp;
		}
	}
	else{
		temp = createExtType(BOOL_t,0,false,NULL,NULL,0,false);
		return temp;
	}
}
