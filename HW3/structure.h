typedef struct attribute attribute;
struct attribute{
	char* typeorvalue;
	char* id;
	attribute* next;
};

typedef struct entry entry;
struct entry{
	char* name;
	char* kind;
	int level;
	char* type;
	attribute* attributelist;
	entry* next;
};

typedef struct symbol_table symbol_table;
struct symbol_table{
	int level;
	entry* entry_list; 
	symbol_table* next;
};



typedef struct idlist idlist;
struct idlist{
	char* id;
	char* arraytype;
	idlist* next;
};

typedef struct constlist constlist;
struct constlist{
	char* id;
	char* value;
	constlist* next;
};

entry* insertentrylist(symbol_table* head,char* name,char* kind,int level,char* type,attribute* attributelist);
int searchentrylist(symbol_table* head,char* id);
symbol_table* buildtablelist();
symbol_table* inserttablelist(symbol_table* head);
int searchattribute(attribute* head,char* id);
int countlength(int a);
symbol_table* poptablelist(symbol_table* head,int Opt_Symbol);
attribute* insertattribute(attribute* head,char* typeorvalue,char* id);
idlist* insertidlist(idlist* head,char* id,char* arraytype);
int searchidlist(idlist* head,char* id);
constlist* insertconstlist(constlist* head,char* id,char* value);
int searchconstlist(constlist* head,char* id);
