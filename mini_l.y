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

  std::string currentLoopTop = "";
%}

%error-verbose

%union{
  int num;
  char* ident;

  struct S {
    char* code;
    char* place;
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
%type <ident> vars comp
%type <expression> expression multiplicative_exp term term_one term_two var idents
%type <expression> bool_exp relation_and_exp relation_exp expressions
%type <statement> statement statements declarations declaration function functions

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

  prog_start: functions 
              {

              }
              ;

  functions: /*empty*/ 
              {
                $$.code = strdup("");
                $$.place = strdup("");
              }
              | function functions
              {
                std::string temp;
                temp.append($1.code);
                temp.append($2.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              ;

  function: FUNCTION IDENT SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY 
              {
                if(strcmp($2, "main") == 0) {
                  mainFunc = true;
                }

                if(funcs.count($2) > 0) {
                  fprintf(stderr, "Error: function %s already defined\n", $2);
                }
                
                funcs.insert($2);



                std::string temp;
                temp += "func ";
                temp += $2;
                temp += "\n";
                temp.append($5.code);
                temp.append($8.code);
                temp.append($11.code);
                temp += "endfunc\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup($2);
              }
              ;

  declarations: /*empty*/ 
              {
                $$.code = strdup("");
                $$.place = strdup("");
              }
              | declaration SEMICOLON declarations 
              {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              ;

  idents: IDENT 
              {
                std::string temp = ". ";
                temp += $1;
                temp += "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup($1);
              }
              | IDENT COMMA idents 
              {
                std::string temp = ". ";
                temp += $1;
                temp += "\n";
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup($1);
              }
              ;

  declaration: idents COLON INTEGER 
              {
                $$.code = strdup($1.code);
                $$.place = strdup("");
              }
              | idents COLON ENUM L_PAREN idents R_PAREN 
              {
                std::string temp;
                temp.append($1.code);
                temp.append($5.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              | idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
              {
                std::string temp;
                temp += ".[] ";
                temp.append($1.place);
                temp += ", ";
                temp += std::to_string($5);
                temp += "\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              ;

  statements: /*empty*/ 
              {
                $$.code = strdup("");
                $$.place = strdup("");
              }
              | statement SEMICOLON statements 
              {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              ;

  statement: var ASSIGN expression 
              {
                std::string temp;
                temp.append($3.code);

                if($1.arr) {
                  temp += "[]= ";
                  temp += $1.place;
                  temp += ", ";
                  temp += $1.code;
                  temp += ", ";
                  temp += $3.place;
                  temp += "\n";
                } else {
                  temp += "= ";
                  temp += $1.place;
                  temp += ", ";
                  temp += $3.place;
                  temp += "\n";
                }

                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              | IF bool_exp THEN statements ENDIF 
              {
                std::string x = new_label();
                std::string after = new_label();
                std::string temp;

                temp.append($2.code);
                temp += "?:= " + x + ", " + $2.place + "\n";
                temp += ":= " + after + "\n";
                temp += ": " + x + "\n";
                temp.append($4.code);          
                temp += ": " + after + "\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              | IF bool_exp THEN statements ELSE statements ENDIF 
              {
                std::string x = new_label();
                std::string after = new_label();
                std::string temp;

                temp.append($2.code);
                temp += "?:= " + x + ", " + $2.place + "\n";
                temp.append($6.code);
                temp += ":= " + after + "\n";
                temp += ": " + x + "\n";
                temp.append($4.code);
                temp += ": " + after + "\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              | WHILE bool_exp BEGINLOOP statements ENDLOOP 
              {
                std::string start = new_label();
                std::string after = new_label();
                std::string temp;

                temp += ": " + start + "\n";
                temp.append($2.code);

                std::string notTemp = new_temp();
                temp += "! " + notTemp + ", " + $2.place + "\n";
                temp += "?:= " + after + ", " + notTemp + "\n";
                currentLoopTop = start;
                temp.append($4.code);
                temp += ":= " + start + "\n";
                temp += ": " + after + "\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              | DO BEGINLOOP statements ENDLOOP WHILE bool_exp 
              {
                  std::string start = new_label();
                  std::string after = new_label();
                  std::string notTemp = new_temp();
                  std::string temp;

                  currentLoopTop = start;

                  temp += ": " + start + "\n";
                  temp.append($3.code);
                  temp.append($6.code);
                  temp += "! " + notTemp + ", " + std::string($6.place) + "\n";
                  temp += "?:= " + after + ", " + notTemp + "\n";
                  temp += ":= " + start + "\n";
                  temp += ": " + after + "\n";

                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
              }
              | FOR vars ASSIGN NUMBER SEMICOLON bool_exp SEMICOLON vars ASSIGN expression BEGINLOOP statements ENDLOOP
              {
                  std::string start = new_label();
                  std::string after = new_label();
                  std::string notTemp = new_temp();
                  std::string temp;

                  temp += "= " + std::string($2) + ", " + std::to_string($4) + "\n";
                  temp += ": " + start + "\n";
                  temp.append($6.code);
                  temp += "! " + notTemp + ", " + std::string($6.place) + "\n";
                  temp += "?:= " + after + ", " + notTemp + "\n";
                  temp.append($12.code);
                  temp.append($10.code);
                  temp += "= " + std::string($8) + ", " + std::string($10.place) + "\n";
                  temp += ":= " + start + "\n";
                  temp += ": " + after + "\n";

                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
              }
              | READ vars 
              {
                std::string temp;
                temp.append($2.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              | WRITE vars
              {
                  std::string temp;
                  temp.append($2.code);
                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
              }
              | CONTINUE
              {
                  std::string temp;
                  temp += ":= " + currentLoopTop + "\n";
                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
              }
              | RETURN expression
              {
                  std::string temp;
                  temp.append($2.code);
                  temp += "ret " + std::string($2.place) + "\n";
                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
              }
              ;

  bool_exp: relation_and_exp 
              {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);
              }
              | relation_and_exp OR bool_exp
              {
                  std::string t = new_temp();
                  std::string temp;

                  temp.append($1.code);
                  temp.append($3.code);
                  temp += "|| " + t + ", " + $1.place + ", " + $3.place + "\n";

                  $$.code = strdup(temp.c_str());
                  $$.place = strdup(t.c_str());
              }
              ;

  relation_and_exp: relation_exp 
              {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);
              }
              | relation_exp AND relation_and_exp 
              {
                std::string t = new_temp();
                std::string temp;

                temp.append($1.code);
                temp.append($3.code);
                temp += "&& " + t + ", " + $1.place + ", " + $3.place + "\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup(t.c_str());
              }
              ;

  relation_exp: NOT expression comp expression
              {
                  std::string t = new_temp();
                  std::string notT = new_temp();
                  std::string temp;

                  temp.append($2.code);
                  temp.append($4.code);
                  temp += std::string($3.place) + " " + t + ", " + $2.place + ", " + $4.place + "\n";
                  temp += "! " + notT + ", " + t + "\n";

                  $$.code = strdup(temp.c_str());
                  $$.place = strdup(notT.c_str());
              }
              | expression comp expression
              {
                  std::string t = new_temp();
                  std::string temp;

                  temp.append($1.code);
                  temp.append($3.code);
                  temp += std::string($2.place) + " " + t + ", " + $1.place + ", " + $3.place + "\n";

                  $$.code = strdup(temp.c_str());
                  $$.place = strdup(t.c_str());
              }
              | NOT TRUE 
              {
                std::string t = new_temp();

                std::string temp = "= " + t + ", 0\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup(t.c_str());
              }
              | TRUE 
              {
                std::string t = new_temp();

                std::string temp = "= " + t + ", 1\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup(t.c_str());
              }
              | NOT FALSE 
              {
                std::string t = new_temp();

                std::string temp = "= " + t + ", 1\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup(t.c_str());
              }
              | FALSE 
              {
                std::string t = new_temp();

                std::string temp = "= " + t + ", 0\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup(t.c_str());
              }
              | NOT L_PAREN bool_exp R_PAREN
              {
                  std::string t = new_temp();
                  std::string temp;
                  temp.append($3.code);
                  temp += "! " + t + ", " + std::string($3.place) + "\n";
                  $$.code = strdup(temp.c_str());
                  $$.place = strdup(t.c_str());
              }
              | L_PAREN bool_exp R_PAREN
              {
                  $$.code = strdup($2.code);
                  $$.place = strdup($2.place);
              }
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