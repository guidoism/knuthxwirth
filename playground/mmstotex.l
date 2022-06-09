%{
#include <stdio.h>
#include "symtab.h"


/* delayed printing */

#define MAXSTR 256

char label[MAXSTR]="";
char op[MAXSTR]="";
char arg[MAXSTR]="";
char comment[MAXSTR]="";
int texmode= 0; /* if (texmode) replace identifiers by defined TeX replacements */
FILE * outfile=NULL;
#define MAXPATH 521
char outpath[MAXPATH];
int ignore=0;
int rtrefignore = 0; /* used to save ignore while processing %%%rt ... */
int error_no=0;

void error(char *msg, char *info)
{ fprintf(stderr,"Error: %s (%s)\n",msg, info);
  error_no++;
}

void open_file(char *name)
{ if (outfile!=NULL)
  { if (name==NULL || strncmp(outpath,name,MAXPATH)!=0)
    { fclose(outfile);
      outfile=NULL;
    }
  }
  if (name!=NULL && outfile==NULL)
  { outfile=fopen(name,"w");
    if (outfile==NULL) fprintf(stderr,"Unable to open file %s\n",name);
    else
    { strncpy(outpath,name,MAXPATH);
      ignore=0;
    }
  }
}

void def_label(char *str, char *label)
{ node *n;
  n = lookup(label);
  if (n!=NULL) error("TeX label redefinition", label);
  n = insert(label);
  set_content(n,str,NULL,0);
}

void add_label(char *str, char *label)
{ if (texmode)
  {  node *n = lookup(label);
     if (n!=NULL && n->name!=NULL) 
     { strcat(str,n->name);
       return;
     }
  }
  strcat(str,label);
}

void print(char *str)
{ if (ignore) return;
  fprintf(outfile?outfile:stdout,"%s",str);
}

void println(char *str)
{ if (str!=NULL) print(str);
  label[0]=op[0]=arg[0]=comment[0]=0;
}

void printline(void)
{ if (!ignore) fprintf(outfile?outfile:stdout,"\t&%s\t&%s\t&%s\t&%s\\cr\n",label,op,arg,comment);
  label[0]=op[0]=arg[0]=comment[0]=0;
}
%}

%s LABEL LO OPCODE OA ARG COMMENT VERBATIM LCOMMENT TEX FILENAME IGNORE STRING RTREF RTPOLY

SPACE     [[:blank:]]
NOSPACE     [^[:blank:]\n]
LABEL    [a-zA-Z:_][a-zA-Z0-9:_]*|[0-9]H
NOLABEL  [^a-zA-Z0-9:_[:blank:]\n]
OPCHAR   [A-Z0-9]
NOOPCHAR [^A-Z0-9\n]
ARGCHAR  [0-9$#,&|()@~<>+*/\-]
ESCCHAR  [_&$^{}\\~#%]
EXTENDED \;{LABEL}?{SPACE}+{OPCHAR}+{SPACE}+
RUNTIME  \&|[^&%\n][^&\n]*\&
TEXCODE  ([^[:blank:]\n&]|(\\([a-zA-Z]+|{NOSPACE}){SPACE}*))
%%
     /* This is how lines start */
<INITIAL>^{SPACE}*\n         println(""); /* empty line */
<INITIAL>^{LABEL}            add_label(label,yytext); BEGIN(LO); /*line starts with label*/
<INITIAL>^{SPACE}+           BEGIN(OPCODE); /* line starts with spaces */
<INITIAL>^"%%%off"           ignore=1; BEGIN(IGNORE);
<INITIAL>^"%%%on"{SPACE}*\n  ignore=0; open_file(NULL);
<INITIAL>^"%%%on"{SPACE}*    ignore=0; BEGIN(FILENAME);
<INITIAL>^"%%%rt"{SPACE}+    BEGIN(RTREF);rtrefignore=ignore; ignore=0;
<INITIAL>^"%%"               BEGIN(VERBATIM);
<INITIAL>^"%"                print("\t&"); BEGIN(LCOMMENT); /* comment indented to the labels */
<INITIAL>^"&"                print("\t&"); BEGIN(LCOMMENT); /* comment indented to the labels */
<INITIAL>^.                  print("\t&"); yyless(0); BEGIN(LCOMMENT); /* comment showing initial char */

<LO>{SPACE}+            BEGIN(OPCODE);

<OPCODE>{OPCHAR}+       strcpy(op,yytext); BEGIN(OA);
<OPCODE>"%"             print("\t&\t&"); BEGIN(LCOMMENT); /* comment indented to the opcodes */
<OPCODE>"&"             print("\t&\t&"); BEGIN(LCOMMENT); /* comment indented to the opcodes */
<OPCODE>.               print("\t&\t&"); yyless(0); BEGIN(LCOMMENT); /* comment showing initial char */

<OA>{SPACE}+            BEGIN(ARG);

<ARG>{EXTENDED}         strcat(arg,yytext); 
<ARG>{ESCCHAR}          strcat(arg,"\\");strcat(arg,yytext);
<ARG>{ARGCHAR}          strcat(arg,yytext);
<ARG>{LABEL}            add_label(arg,yytext);
<ARG>\'{ESCCHAR}\'      strcat(arg,"'\\");strcat(arg,yytext+1);
<ARG>\'.\'              strcat(arg,yytext); /* char constant */
<ARG>\"                 strcat(arg,yytext); BEGIN(STRING);/* string constant */
<ARG>{SPACE}+           BEGIN(COMMENT);

<STRING>\"              strcat(arg,yytext);BEGIN(ARG);
<STRING>{ESCCHAR}       strcat(arg,"\\");strcat(arg,yytext);
<STRING>.               strcat(arg,yytext);
<STRING>\n              error("String not terminated", arg);printline(); BEGIN(INITIAL);  

<COMMENT>"%%hide"{SPACE}* BEGIN(IGNORE); /* hide this line */
<COMMENT>"%%tex"{SPACE}*  BEGIN(TEX);
<COMMENT>"%"              ; /* ignore '%' when it starts a comment */
<COMMENT>{RUNTIME}.*      strcpy(comment,yytext); /* comment with '&' */
<COMMENT>[^%&\n].*        comment[0]='&'; strcpy(comment+1,yytext); /* comment without runtime */

<VERBATIM>.*\n          println(yytext); BEGIN(INITIAL);

<LCOMMENT>.*            print("\\rm ");print(yytext); 
<LCOMMENT>\n            println("\\hidewidth\\cr\n"); BEGIN(INITIAL);


<TEX>{TEXCODE}+         if (label[0]!=0) {def_label(yytext,label); if (texmode) strcpy(label,yytext);} BEGIN(COMMENT);          

<FILENAME>{NOSPACE}+        open_file(yytext); BEGIN(IGNORE);

<RTREF>[^[:blank:]\n&]+ print("\\rtref|");print(yytext);
<RTREF>[[:blank:]]      ;
<RTREF>\&{SPACE}*       print("|");BEGIN(RTPOLY);
<RTPOLY>.*              print(yytext);
<RTPOLY>\n              println("|\n");ignore=rtrefignore;BEGIN(INITIAL);

<IGNORE>.*\n            println(NULL); BEGIN(INITIAL);

<*>\n                   printline(); BEGIN(INITIAL); 
<*>.                    ;
%%



int main(int argc, char * argv[])
{ while (argc>1)
  { if (argv[1][0]=='-')
    { if (argv[1][1]=='t') texmode=1;
    }
    else 
      open_file(argv[1]);
    argv++;
    argc--;
  }
  yylex();
  if (outfile!=NULL) fclose(outfile);
  return error_no;
}

