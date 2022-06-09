#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "symtab.h"


#define HSIZE 211

static int level=0;
static node *table[HSIZE] = {0};

static unsigned int hvalue(char *s)
{ unsigned int i=0;
  while (*s) i= (i<<2)+*s++;
  return i % HSIZE;
}

static node *newnode(char *s)
{ node *n;
  n = (node *)malloc(sizeof(*n));
  assert(n!=NULL);
  memset(n,0,sizeof(*n));
  n->next=NULL;
  n->symbol = (char *)malloc(strlen(s)+1);
  assert(n->symbol!=NULL);
  strcpy(n->symbol,s);
  n->level=level;
  return n;
}

void set_content(node *n, char *name, void *ptr, symtag tag)
{ if (name!=NULL)
  { if (n->name!=NULL) free(n->name);
    n->name=malloc(strlen(name)+1);
    if (n->name==NULL) 
    { fprintf(stderr,"Out of memory, storing '%s' in %s\n",name, n->symbol);
      exit(1);
    }
    strcpy(n->name,name);
  }
  n->ptr=ptr;
  n->tag=tag;
}

static void free_node(node *n)
{ if  (n->name!=NULL)
    free(n->name);
  free(n);
}
  
    


node *insert(char *s)
{ node *n;
  unsigned int i;
  n = newnode(s);
  i = hvalue(s);
  n->next=table[i];
  table[i] = n;
  return n;
}


node *insert_global(char *s)
{ node *p, **n;
  p = newnode(s);
  p->level=0;
  n= table+hvalue(s);
  while (*n!=NULL)
    n=&((*n)->next);
  *n=p;
  return p;
}



node *lookup(char *s)
{ node *n;
  n = table[hvalue(s)];
  while (n!=NULL)
    if (strcmp(s,n->symbol)==0)
      return n;
    else
      n=n->next;   
  return n;
}


void scope_open(void)
{ level++;
}

void scope_close(void)
{ int i;
  level--;
  for (i=0; i< HSIZE; i++)
    while (table[i]!=NULL && table[i]->level>level)
    { node *n;
      n=table[i];
      table[i]=n->next;
      free_node(n);
    }
}
