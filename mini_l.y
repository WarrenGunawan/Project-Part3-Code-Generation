    /* cs152-miniL phase3 */
%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <map>
  #include <string.h>
  #include <set>
  #include <string>


  int yylex(void);
  int yyparse();
  void yyerror(const char *msg);

  extern char* yytext;
  extern int currPos;
  extern int currLine;
  extern FILE *yyin;

  std::map<std::string, std::string> varTemp;
  std::map<std::string, int> arrSize;
  bool mainFunc = false;
  std::set<std::string> funcs;
  std::set<std::string> reserved {"function", "beginparams", "endparams",
    "beginlocals", "endlocals", "beginbody", "endbody",
    "integer", "array", "enum", "of",
    "if", "then", "endif", "else",
    "for", "while", "do", "beginloop", "endloop",
    "continue", "read", "write",
    "and", "or", "not",
    "true", "false",
    "return"};

  std::string new_temp();
  std::string new_label();
%}

%error-verbose

%union{
  int num;
  char* ident;

  struct S {
    char* code;
  } statement;

  struct E {
    char* place;
    char* code;
    bool arr;
  } expression;
}

%start prog_start


%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE FOR WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE AND OR NOT TRUE FALSE RETURN SUB ADD MULT DIV MOD EQ NEQ LTE GTE LT GT ASSIGN SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET
%token <ident> IDENT
%token <num> NUMBER
%type <ident> idents vars comp
%type <expression> expression multiplicative_exp term term_one term_two var
%type <expression> bool_exp relation_and_exp relation_exp comp expressions
%type <statement> statement statements declarations declaration function

%right ASSIGN
%left OR
%left AND
%right NOT
%left LT LTE GT GTE EQ NEQ
%left ADD SUB
%left MULT DIV MOD

%locations


/* %start program */

%% 

  prog_start: functions {printf("prog_start -> functions\n");}
              ;

  functions: /*empty*/ {printf("functions -> epsilon \n");}
              | function functions {printf("functions -> function functions\n");}
              ;

  function: FUNCTION IDENT SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {printf("function -> FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY\n");}
              ;

  declarations: /*empty*/ {printf("declarations -> epsilon\n");}
              | declaration SEMICOLON declarations {printf("declarations -> declaration SEMICOLON declarations\n");}
              ;

  idents: IDENT {printf("idents -> IDENT\n");}
              | IDENT COMMA idents {printf("idents -> IDENT COMMA idents\n");}
              ;

  declaration: idents COLON INTEGER {printf("declaration -> idents COLON INTEGER\n");}
              | idents COLON ENUM L_PAREN idents R_PAREN {printf("declaration -> idents COLON ENUM L_PAREN idents R_PAREN\n");}
              | idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {printf("declaration -> idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER\n");}
              ;

  statements: /*empty*/ {printf("statements -> epsilon\n");}
              | statement SEMICOLON statements {printf("statements -> statement SEMICOLON statements\n");}
              ;

  statement: var ASSIGN expression {printf("statement -> var ASSIGN expression\n");}
              | IF bool_exp THEN statements ENDIF {printf("statement -> IF bool_exp THEN statements ENDIF\n");}
              | IF bool_exp THEN statements ELSE statements ENDIF {printf("statement -> IF bool_exp THEN statements ELSE statements ENDIF\n");}
              | WHILE bool_exp BEGINLOOP statements ENDLOOP {printf("statement -> WHILE bool_exp BEGINLOOP statements ENDLOOP\n");}
              | DO BEGINLOOP statements ENDLOOP WHILE bool_exp {printf("statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_exp\n");}
              | FOR vars ASSIGN NUMBER SEMICOLON bool_exp SEMICOLON vars ASSIGN expression BEGINLOOP statements ENDLOOP {printf("statement -> FOR vars ASSIGN NUMBER SEMICOLON bool_exp SEMICOLON vars ASSIGN expression BEGINLOOP statements ENDLOOP\n");}
              | READ vars {printf("statement -> READ vars\n");}
              | WRITE vars {printf("statement -> WRITE vars\n");}
              | CONTINUE {printf("statement -> CONTINUE\n");}
              | RETURN expression {printf("statement -> RETURN expression\n");}
              ;

  bool_exp: relation_and_exp {printf("bool_exp -> relation_and_exp\n");}
              | relation_and_exp OR bool_exp {printf("statement -> relation_and_exp OR bool_exp\n");}
              ;

  relation_and_exp: relation_exp {printf("relation_and_exp -> relatio_exp\n");}
              | relation_exp AND relation_and_exp {printf("relation_and_exp -> relation_exp AND relation_and_exp\n");}
              ;

  relation_exp: NOT expression comp expression {printf("relation_exp -> NOT expression comp expression\n");}
              | expression comp expression {printf("relation_exp -> expression comp expression\n");}
              | NOT TRUE {printf("relation_exp -> NOT TRUE\n");}
              | TRUE {printf("relation_exp -> TRUE\n");}
              | NOT FALSE {printf("relation_exp -> NOT FALSE\n");}
              | FALSE {printf("relation_exp -> FALSE\n");}
              | NOT L_PAREN bool_exp R_PAREN {printf("relation_exp -> NOT L_PAREN bool_exp R_PAREN\n");}
              | L_PAREN bool_exp R_PAREN {printf("relation_exp -> L_PAREN bool_exp R_PAREN\n");}
              ;

  comp: EQ {printf("comp -> EQ\n");}
              | NEQ {printf("comp -> NEQ\n");}
              | LTE {printf("comp -> LTE\n");}
              | LT {printf("comp -> LT\n");}
              | GTE {printf("comp -> GTE\n");}
              | GT {printf("comp -> GT\n");}
              ;

  expression: multiplicative_exp {printf("expression -> multiplicative_exp SEMICOLON\n");}
              | multiplicative_exp ADD expression {printf("expression -> multiplicative_exp ADD expression\n");}
              | multiplicative_exp SUB expression {printf("expression -> multiplicative_exp SUB expression\n");}
              ;

  multiplicative_exp: term {printf("multiplicative_exp -> term\n");}
              | term MULT multiplicative_exp {printf("multiplicative_exp -> term MULT multiplicative_exp\n");}
              | term DIV multiplicative_exp {printf("multiplicative_exp -> term DIV multiplicative_exp\n");}
              | term MOD multiplicative_exp {printf("multiplicative_exp -> term MOD multiplicative_exp\n");}
              ;

  term: term_one {printf("term -> term_one\n");}
              | term_two {printf("term -> term_two\n");}
              ;

  term_one: SUB var {printf("term_one -> SUB var\n");}
              | var {printf("term_one -> var\n");}
              | SUB NUMBER {printf("term_one -> SUB NUMBER\n");}
              | NUMBER {printf("term_one -> NUMBER\n");}
              | SUB L_PAREN expression R_PAREN {printf("term_one -> SUB L_PAREN expression R_PAREN\n");}
              | L_PAREN expression R_PAREN {printf("term_one -> L_PAREN expression R_PAREN\n");}
              ;

  term_two: IDENT L_PAREN expressions_opt R_PAREN {printf("term_two -> IDENT L_PAREN expressions_opt R_PAREN\n");}
              ;

  expressions_opt: /*empty*/ {printf("expressions_opt -> epsilon\n");}
              | expressions {printf("expressions_opt -> expressions\n");}
              ;

  expressions: expression {printf("expressions -> expression\n");}
              | expression COMMA expressions {printf("expressions -> expression COMMA expressions\n");}
              ;

  vars: var {printf("vars -> var\n");} 
              | var COMMA vars {printf("vars -> var COMMA vars\n");}
              ;

  var: IDENT {printf("var -> IDENT\n");}
              | IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET {printf("var -> IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n");}
              ;


%% 

int main(int argc, char **argv) {
  if (argc > 1) {
    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
      fprintf(stderr, "Error: could not open file %s\n", argv[1]);
      return 1;
    }
  }

  return yyparse();
}

void yyerror(const char *msg) {
  fprintf(stderr, "Syntax error at line %d, column %d: %s\n", currLine, currPos, msg);
}

std::string new_temp() {
    static int count = 0;
    return "_t" + std::to_string(count++);
}

std::string new_label() {
    static int count = 0;
    return "label_" + std::to_string(count++);
}