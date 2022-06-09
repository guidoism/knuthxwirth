#ifndef SYMTAB_H
#define SYMTAB_H 

#include <stdio.h>

typedef enum {undef=0, string, file, ref, number} symtag;

typedef struct node {
  /* required */
  struct node *next;
  char *symbol;
  int level;
  symtag tag;
  char *name; 
  void *ptr;
  int i;
}  node;

extern node *insert(char *s);
extern node *insert_global(char *s);
extern node *lookup(char *s);
extern void scope_open(void);
extern void scope_close(void);
extern void set_content(node *n, char *name, void *ptr, symtag tag);

#endif
