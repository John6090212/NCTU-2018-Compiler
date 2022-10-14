#include"datatype.h"
int initSymTableList(struct SymTableList *list);
int destroySymTableList(struct SymTableList *list);
//

int AddSymTable(struct SymTableList* list);
struct SymTable* deleteSymTable(struct SymTable* target);
int deleteLastSymTable(struct SymTableList* list);
int insertTableNode(struct SymTable *table,struct SymTableNode* newNode);
//
struct SymTableNode* deleteTableNode(struct SymTableNode* target);
struct SymTableNode* createVariableNode(const char* name,int level,struct ExtType* type);
struct SymTableNode* createFunctionNode(const char* name,int level,struct ExtType* type,struct Attribute* attr);
struct SymTableNode* createConstNode(const char* name,int level,struct ExtType* type,struct Attribute* attr);
struct SymTableNode* createParameterNode(const char* name,int level,struct ExtType* type);
//
struct Attribute* createFunctionAttribute(struct FuncAttrNode* list);
struct Attribute* createConstantAttribute(BTYPE type,void* value);
struct FuncAttrNode* deleteFuncAttrNode(struct FuncAttrNode* target);
int killAttribute(struct Attribute* target);
struct FuncAttrNode* createFuncAttrNode(struct ExtType* type,const char* name);
int connectFuncAttrNode(struct FuncAttrNode* head, struct FuncAttrNode* newNode);
//
struct ExtType* createExtType(BTYPE baseType,int intvalue,bool isArray,struct ArrayDimNode* dimArray,int *intarrayvalue,int intarraysize,bool has_initialvalue);
int killExtType(struct ExtType* target);
//
struct ArrayDimNode* createArrayDimNode(int size);
int connectArrayDimNode(struct ArrayDimNode* head,struct ArrayDimNode* newNode);
struct ArrayDimNode* deleteArrayDimNode(struct ArrayDimNode* target);
//
struct SymTableNode* findFuncDeclaration(struct SymTable* table,const char* name);
int printSymTable(struct SymTable* table);
int printType(struct ExtType* extType);
int printConstAttribute(struct ConstAttr* constAttr);
int printParamAttribute(struct FuncAttr* funcAttr);

//
struct VariableList* createVariableList(struct Variable* head);
int deleteVariableList(struct VariableList* list);
int connectVariableList(struct VariableList* list,struct Variable* node);
struct Variable* createVariable(const char* name,struct ExtType* type,struct VariableList* array_initial);
struct Variable* deleteVariable(struct Variable* target);

//new create
struct FuncDeclNode* insertFuncDeclList(struct FuncDeclNode* decllist,struct SymTableNode* newNode); 
struct FuncDeclNode* searchFuncDeclList(struct FuncDeclNode* decllist,const char* name);
void checkFuncDeclList(struct FuncDeclNode* decllist,int linenum);
bool compareFuncAttrNode(struct FuncAttrNode* node1,struct FuncAttrNode* node2);
bool compareExtType(struct ExtType* type1,struct ExtType* type2);
struct SymTableNode* findSymTableNode(struct SymTable* table,const char* name);
bool findFuncAttrNode(struct FuncAttrNode* head,const char* name);
struct ExtType* unarySUB_OPcheck(struct ExtType* operand,int linenum);
struct ExtType* MUL_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum);
BTYPE typecoercion(BTYPE first,BTYPE second);
struct ExtType* DIV_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum);
struct ExtType* MOD_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum);
struct ExtType* ADD_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum);
struct ExtType* SUB_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum);
struct ExtType* rel_op4check(struct ExtType* operand1,struct ExtType* operand2,REL_OP rel_op,int linenum);
struct ExtType* rel_op2check(struct ExtType* operand1,struct ExtType* operand2,REL_OP rel_op,int linenum);
struct ExtType* NOT_OPcheck(struct ExtType* operand,int linenum);
struct ExtType* AND_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum);
struct ExtType* OR_OPcheck(struct ExtType* operand1,struct ExtType* operand2,int linenum);
