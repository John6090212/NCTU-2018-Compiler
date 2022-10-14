//symbol table linked list 
//symbol table include level ,entry linked list
//entry include name,kind,level,type,attribute
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "structure.h"

entry* insertentrylist(symbol_table* head,char* name,char* kind,int level,char* type,attribute* attributelist){
	//printf("insertentrylist start\n");
	entry* first = (entry*)malloc(sizeof(entry));
	first->name = (char*)malloc(strlen(name)+1);
	strcpy(first->name,name);
	first->kind = (char*)malloc(strlen(kind)+1);
	strcpy(first->kind,kind);
	first->level = level;
	first->type = (char*)malloc(strlen(type)+1);
	strcpy(first->type,type);
	first->attributelist = attributelist;

	if(head->entry_list == NULL){
		head->entry_list = first;
		//printf("insertentrylist end\n");
		return head->entry_list;
	}
	else{
		entry* current = head->entry_list;
		while(current->next != NULL){
			current = current->next;
		}
		current->next = first;
		//printf("insertentrylist end\n");
		return head->entry_list;
	}
}

int searchentrylist(symbol_table* head,char* id){
	//printf("searchentrylist start\n");
	entry* current = head->entry_list;
	//printf("current = head->entry_list finish\n");
	
	while(current != NULL){
		if(strcmp(current->name,id) == 0){
			//printf("searchentrylist end\n");
			return 0;
		}
		current = current->next;
	}
	//printf("searchentrylist end\n");
	return 1;
}



symbol_table* buildtablelist(){
	//printf("buildtablelist start\n");
	symbol_table* first = (symbol_table*)malloc(sizeof(symbol_table));
	first->level = 0;
	first->entry_list = NULL;
	first->next = NULL;
	//printf("buildtablelist end\n");
	return first;
}



symbol_table* inserttablelist(symbol_table* head){
	//printf("inserttablelist start\n");
	if(head == NULL){
		head = buildtablelist();
		//printf("inserttablelist end\n");
		return head;
	}
	else{
		symbol_table* node = (symbol_table*)malloc(sizeof(symbol_table));
		node->level = head->level + 1;
		node->next = head;
		node->entry_list = NULL;
		head = node;
		//printf("inserttablelist end\n");
		return head;
	} 
	
}

int countlength(int a){
	int count = 0;
	do{
		count++;
		a /= 10;
	}while(a);
	return count;
}

symbol_table* poptablelist(symbol_table* head,int Opt_Symbol){
	//printf("poptablelist start\n");
	entry* current = head->entry_list;
	entry* tmp;
	if(Opt_Symbol){
		printf("=======================================================================================\n");
		printf("Name                             Kind       Level       Type               Attribute               \n");
		printf("---------------------------------------------------------------------------------------\n");
	}
	while(current != NULL){
		if(Opt_Symbol){
			printf("%-33s%-11s",current->name,current->kind);
			int length = countlength(current->level);
			char* s;
			if(current->level){
				char* local = "(local)";
				s = (char*)malloc(strlen(local)+length+1);
				sprintf(s,"%d",current->level);
				strcat(s,local);
				printf("%-12s",s);
			}
			else{
				char* global = "(global)";
				s = (char*)malloc(strlen(global)+length+1);
				sprintf(s,"%d",current->level);
				strcat(s,global);
				printf("%-12s",s);
			}
			if(strlen(current->type) <= 19){
				printf("%-19s",current->type);
			}
			else{
				printf("%s",current->type);
			}
		}
		attribute* ahead = current->attributelist;
		while(ahead != NULL){
			if(Opt_Symbol){
				if(ahead->next == NULL){
					printf("%s",ahead->typeorvalue);
				}
				else{
					printf("%s,",ahead->typeorvalue);
				}
			}
			
			ahead = ahead->next;
		}
		if(Opt_Symbol){
			printf("\n");
		}
		current = current->next;
	}
	if(Opt_Symbol){
		printf("======================================================================================\n");
	}
	head = head->next;
	//printf("poptablelist end\n");
	return head;
}

//need to free the memory
attribute* insertattribute(attribute* head,char* typeorvalue,char* id){
	//printf("insertattribute start\n");
	attribute* first = (attribute*)malloc(sizeof(attribute));
	//printf("first malloc finish\n");
	first->typeorvalue = (char*) malloc(strlen(typeorvalue)+1);
	//printf("typeorvalue malloc finish\n");
	strcpy(first->typeorvalue,typeorvalue);
	//printf("typeorvalue strcpy finish\n");
	first->id = (char*) malloc(strlen(id)+1);
	//printf("id malloc finish\n");
	strcpy(first->id,id);
	//printf("id strcpy finish\n");
	first->next = NULL;
	if(head == NULL){
		head = first;
	//printf("insertattribute end\n");
		return head;
	}
	else{
		attribute* current = head;
		while(current->next != NULL){
			current = current->next;
		}
		current->next = first;
		//printf("insertattribute end\n");
		return head;
	}
}

int searchattribute(attribute* head,char* id){
	//printf("searchattribute start\n");
	attribute* current = head;
	while(current != NULL){
		if(strcmp(current->id,id) == 0){
			//printf("searchattribute end\n");
			return 0;
		}
		current = current->next;
	}
	//printf("searchattribute end\n");
	return 1;
}

idlist* insertidlist(idlist* head,char* id,char* arraytype){
	//printf("insertidlist start\n");
	idlist* first = (idlist*)malloc(sizeof(idlist));
	first->id = (char*) malloc(strlen(id)+1);
	//printf("malloc fisrt->id finish\n");
	strcpy(first->id,id);
	//printf("strcpy fisrt->id finish\n");
	if(arraytype == NULL){
		first->arraytype = NULL;
	}
	else{
		first->arraytype = (char*) malloc(strlen(arraytype)+1);
		//printf("malloc fisrt->arraytype finish\n");
		strcpy(first->arraytype,arraytype);
		//printf("malloc fisrt->arraytype finish\n");
	}
	
	first->next = NULL;
	//printf("fisrt->next initial finish\n");
	if(head == NULL){
		//printf("start assign head = first\n");
		head = first;
		//printf("insertidlist end\n");
		return head;
	}
	else{
		idlist* current = head;
		while(current->next != NULL){
			current = current->next;
		}
		current->next = first;
		//printf("insertidlist end\n");
		return head;
	}
}

int searchidlist(idlist* head,char* id){
	//printf("searchidlist start\n");
	idlist* current = head;
	while(current != NULL){
		//printf("%s\n",id);
		//printf("%s\n",current->id);
		if(strcmp(current->id,id) == 0){
			//printf("searchidlist end\n");
			return 0;
		}
		current = current->next;
	}
	//printf("searchidlist end\n");
	return 1;
}

constlist* insertconstlist(constlist* head,char* id,char* value){
	//printf("inserconstlist start\n");
	constlist* first = (constlist*)malloc(sizeof(constlist));
	first->id = (char*) malloc(strlen(id)+1);
	strcpy(first->id,id);
	
	first->value = (char*) malloc(strlen(value)+1);
	strcpy(first->value,value);
	
	first->next = NULL;
	
	if(head == NULL){
		head = first;
		//printf("inserconstlist end\n");
		return head;
	}
	else{
		constlist* current = head;
		while(current->next != NULL){
			current = current->next;
		}
		current->next = first;
		//printf("inserconstlist end\n");
		return head;
	}
}

int searchconstlist(constlist* head,char* id){
	//printf("searchconstlist start\n");
	constlist* current = head;
	while(current != NULL){
		if(strcmp(current->id,id) == 0){
			//printf("searchconstlist end\n");
			return 0;
		}
		current = current->next;
	}
	//printf("searchconstlist end\n");
	return 1;
}
