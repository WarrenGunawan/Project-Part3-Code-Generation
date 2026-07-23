    /* cs152-miniL phase3 */
%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <map>
  #include <string.h>
  #include <set>
  #include <sstream>
  #include <string>
  #include <vector>


  int yylex(void);
  int yyparse();
  void yyerror(const char *msg);

  extern char* yytext;
  extern int currPos;
  extern int currLine;
  extern FILE *yyin;

  struct Symbol {
    bool isArray;
    int arraySize;
  };

  struct FunctionCall {
    std::string name;
    int line;
  };

  std::map<std::string, Symbol> symbols;
  bool mainFunc = false;
  bool semanticError = false;
  std::string currentFunction;
  std::set<std::string> funcs;
  std::set<std::string> generatedTemps;
  std::vector<FunctionCall> functionCalls;
  std::vector<std::string> loopLabels;
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
  std::string parameter_assignments(const char *declarationCode);
  void begin_function(const char *name, int line);
  std::string declare_symbols(const char *names, bool isArray, int arraySize, int line);
  const Symbol *lookup_symbol(const char *name, int line);
  void semantic_error(int line, const std::string &message);
  void validate_program();
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
    char* index;
    bool arr;
  } expression;
}

%start prog_start


%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE FOR WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE AND OR NOT TRUE FALSE RETURN SUB ADD MULT DIV MOD EQ NEQ LTE GTE LT GT ASSIGN SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET
%token <ident> IDENT
%token <num> NUMBER
%type <ident> comp
%type <expression> expression multiplicative_exp term term_one term_two var vars idents
%type <expression> bool_exp relation_and_exp relation_exp expressions expressions_opt
%type <statement> statement statements declarations declaration function functions function_header loop_marker

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
                validate_program();
                if(!semanticError) {
                  printf("%s", $1.code);
                }
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

  function_header: FUNCTION IDENT SEMICOLON
              {
                begin_function($2, @2.first_line);
                $$.code = strdup("");
                $$.place = strdup($2);
              }
              ;

  function: function_header BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
              {
                std::string temp;
                temp += "func ";
                temp += $1.place;
                temp += "\n";
                temp.append($3.code);
                temp.append(parameter_assignments($3.code));
                temp.append($6.code);
                for(const std::string &name : generatedTemps) {
                  temp += ". " + name + "\n";
                }
                temp.append($9.code);
                temp += "endfunc\n";

                generatedTemps.clear();

                $$.code = strdup(temp.c_str());
                $$.place = strdup($1.place);
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
                std::string names = std::string($1) + "\n";
                $$.code = strdup(names.c_str());
                $$.place = strdup($1);
              }
              | IDENT COMMA idents 
              {
                std::string names = std::string($1) + "\n" + $3.code;
                $$.code = strdup(names.c_str());
                $$.place = strdup($1);
              }
              ;

  declaration: idents COLON INTEGER 
              {
                std::string code = declare_symbols($1.code, false, 0, @1.first_line);
                $$.code = strdup(code.c_str());
                $$.place = strdup("");
              }
              | idents COLON ENUM L_PAREN idents R_PAREN 
              {
                std::string code = declare_symbols($1.code, false, 0, @1.first_line);
                code += declare_symbols($5.code, false, 0, @5.first_line);
                $$.code = strdup(code.c_str());
                $$.place = strdup("");
              }
              | idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
              {
                if($5 <= 0) {
                  semantic_error(@5.first_line, "array size must be greater than zero");
                }
                std::string code = declare_symbols($1.code, true, $5, @1.first_line);
                $$.code = strdup(code.c_str());
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
                temp.append($1.code);
                temp.append($3.code);

                if($1.arr) {
                  temp += "[]= ";
                  temp += $1.place;
                  temp += ", ";
                  temp += $1.index;
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
              | WHILE bool_exp BEGINLOOP loop_marker statements ENDLOOP
              {
                std::string start = $4.place;
                std::string after = new_label();
                std::string temp;

                temp += ": " + start + "\n";
                temp.append($2.code);

                std::string notTemp = new_temp();
                temp += "! " + notTemp + ", " + $2.place + "\n";
                temp += "?:= " + after + ", " + notTemp + "\n";
                temp.append($5.code);
                temp += ":= " + start + "\n";
                temp += ": " + after + "\n";

                loopLabels.pop_back();

                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              | DO BEGINLOOP loop_marker statements ENDLOOP WHILE bool_exp
              {
                  std::string start = new_label();
                  std::string continueLabel = $3.place;
                  std::string after = new_label();
                  std::string notTemp = new_temp();
                  std::string temp;

                  temp += ": " + start + "\n";
                  temp.append($4.code);
                  temp += ": " + continueLabel + "\n";
                  temp.append($7.code);
                  temp += "! " + notTemp + ", " + std::string($7.place) + "\n";
                  temp += "?:= " + after + ", " + notTemp + "\n";
                  temp += ":= " + start + "\n";
                  temp += ": " + after + "\n";

                  loopLabels.pop_back();

                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
              }
              | FOR vars ASSIGN NUMBER SEMICOLON bool_exp SEMICOLON vars ASSIGN expression BEGINLOOP loop_marker statements ENDLOOP
              {
                  std::string start = new_label();
                  std::string continueLabel = $12.place;
                  std::string after = new_label();
                  std::string notTemp = new_temp();
                  std::string temp;

                  temp += "= " + std::string($2.index) + ", " + std::to_string($4) + "\n";
                  temp += ": " + start + "\n";
                  temp.append($6.code);
                  temp += "! " + notTemp + ", " + std::string($6.place) + "\n";
                  temp += "?:= " + after + ", " + notTemp + "\n";
                  temp.append($13.code);
                  temp += ": " + continueLabel + "\n";
                  temp.append($10.code);
                  temp += "= " + std::string($8.index) + ", " + std::string($10.place) + "\n";
                  temp += ":= " + start + "\n";
                  temp += ": " + after + "\n";

                  loopLabels.pop_back();

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
                  temp.append($2.place);
                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
              }
              | CONTINUE
              {
                  std::string temp;
                  if(loopLabels.empty()) {
                    semantic_error(@1.first_line, "continue statement not within a loop");
                  } else {
                    temp += ":= " + loopLabels.back() + "\n";
                  }
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

  loop_marker: /*empty*/
              {
                std::string label = new_label();
                loopLabels.push_back(label);
                $$.code = strdup("");
                $$.place = strdup(label.c_str());
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
                  temp += std::string($3) + " " + t + ", " + $2.place + ", " + $4.place + "\n";
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
                  temp += std::string($2) + " " + t + ", " + $1.place + ", " + $3.place + "\n";

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




  comp: EQ {$$ = strdup("==");}
              | NEQ {$$ = strdup("!=");}
              | LTE {$$ = strdup("<=");}
              | LT {$$ = strdup("<");}
              | GTE {$$ = strdup(">=");}
              | GT {$$ = strdup(">");}
              ;

  expression: multiplicative_exp
              {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);
                $$.index = strdup("");
                $$.arr = false;
              }
              | expression ADD multiplicative_exp
              {
                std::string t = new_temp();
                std::string code = std::string($1.code) + $3.code;
                code += "+ " + t + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(code.c_str());
                $$.place = strdup(t.c_str());
                $$.index = strdup("");
                $$.arr = false;
              }
              | expression SUB multiplicative_exp
              {
                std::string t = new_temp();
                std::string code = std::string($1.code) + $3.code;
                code += "- " + t + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(code.c_str());
                $$.place = strdup(t.c_str());
                $$.index = strdup("");
                $$.arr = false;
              }
              ;

  multiplicative_exp: term
              {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);
                $$.index = strdup("");
                $$.arr = false;
              }
              | multiplicative_exp MULT term
              {
                std::string t = new_temp();
                std::string code = std::string($1.code) + $3.code;
                code += "* " + t + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(code.c_str());
                $$.place = strdup(t.c_str());
                $$.index = strdup("");
                $$.arr = false;
              }
              | multiplicative_exp DIV term
              {
                std::string t = new_temp();
                std::string code = std::string($1.code) + $3.code;
                code += "/ " + t + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(code.c_str());
                $$.place = strdup(t.c_str());
                $$.index = strdup("");
                $$.arr = false;
              }
              | multiplicative_exp MOD term
              {
                std::string t = new_temp();
                std::string code = std::string($1.code) + $3.code;
                code += "% " + t + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(code.c_str());
                $$.place = strdup(t.c_str());
                $$.index = strdup("");
                $$.arr = false;
              }
              ;

  term: term_one
              {
                $$ = $1;
              }
              | term_two
              {
                $$ = $1;
              }
              ;

  term_one: SUB var
              {
                std::string operand;
                std::string code = $2.code;
                if($2.arr) {
                  std::string loaded = new_temp();
                  code += "=[] " + loaded + ", " + $2.place + ", " + $2.index + "\n";
                  operand = loaded;
                } else {
                  operand = $2.place;
                }
                std::string t = new_temp();
                code += "- " + t + ", 0, " + operand + "\n";
                $$.code = strdup(code.c_str());
                $$.place = strdup(t.c_str());
                $$.index = strdup("");
                $$.arr = false;
              }
              | var
              {
                if($1.arr) {
                  std::string t = new_temp();
                  std::string code = $1.code;
                  code += "=[] " + t + ", " + $1.place + ", " + $1.index + "\n";
                  $$.code = strdup(code.c_str());
                  $$.place = strdup(t.c_str());
                } else {
                  $$.code = strdup($1.code);
                  $$.place = strdup($1.place);
                }
                $$.index = strdup("");
                $$.arr = false;
              }
              | SUB NUMBER
              {
                std::string value = "-" + std::to_string($2);
                $$.code = strdup("");
                $$.place = strdup(value.c_str());
                $$.index = strdup("");
                $$.arr = false;
              }
              | NUMBER
              {
                std::string value = std::to_string($1);
                $$.code = strdup("");
                $$.place = strdup(value.c_str());
                $$.index = strdup("");
                $$.arr = false;
              }
              | SUB L_PAREN expression R_PAREN
              {
                std::string t = new_temp();
                std::string code = $3.code;
                code += "- " + t + ", 0, " + $3.place + "\n";
                $$.code = strdup(code.c_str());
                $$.place = strdup(t.c_str());
                $$.index = strdup("");
                $$.arr = false;
              }
              | L_PAREN expression R_PAREN
              {
                $$.code = strdup($2.code);
                $$.place = strdup($2.place);
                $$.index = strdup("");
                $$.arr = false;
              }
              ;

  term_two: IDENT L_PAREN expressions_opt R_PAREN
              {
                functionCalls.push_back({$1, @1.first_line});
                std::string t = new_temp();
                std::string code = $3.code;
                code += "call " + std::string($1) + ", " + t + "\n";
                $$.code = strdup(code.c_str());
                $$.place = strdup(t.c_str());
                $$.index = strdup("");
                $$.arr = false;
              }
              ;

  expressions_opt: /*empty*/
              {
                $$.code = strdup("");
                $$.place = strdup("");
                $$.index = strdup("");
                $$.arr = false;
              }
              | expressions
              {
                $$ = $1;
              }
              ;

  expressions: expression
              {
                std::string code = $1.code;
                code += "param " + std::string($1.place) + "\n";
                $$.code = strdup(code.c_str());
                $$.place = strdup("");
                $$.index = strdup("");
                $$.arr = false;
              }
              | expression COMMA expressions
              {
                std::string code = $1.code;
                code += "param " + std::string($1.place) + "\n";
                code += $3.code;
                $$.code = strdup(code.c_str());
                $$.place = strdup("");
                $$.index = strdup("");
                $$.arr = false;
              }
              ;

  vars: var
              {
                std::string readCode = $1.code;
                std::string writeCode = $1.code;
                if($1.arr) {
                  readCode += ".[]< " + std::string($1.place) + ", " + $1.index + "\n";
                  writeCode += ".[]> " + std::string($1.place) + ", " + $1.index + "\n";
                } else {
                  readCode += ".< " + std::string($1.place) + "\n";
                  writeCode += ".> " + std::string($1.place) + "\n";
                }
                $$.code = strdup(readCode.c_str());
                $$.place = strdup(writeCode.c_str());
                $$.index = strdup($1.place);
                $$.arr = false;
              }
              | var COMMA vars
              {
                std::string readCode = $1.code;
                std::string writeCode = $1.code;
                if($1.arr) {
                  readCode += ".[]< " + std::string($1.place) + ", " + $1.index + "\n";
                  writeCode += ".[]> " + std::string($1.place) + ", " + $1.index + "\n";
                } else {
                  readCode += ".< " + std::string($1.place) + "\n";
                  writeCode += ".> " + std::string($1.place) + "\n";
                }
                readCode += $3.code;
                writeCode += $3.place;
                $$.code = strdup(readCode.c_str());
                $$.place = strdup(writeCode.c_str());
                $$.index = strdup($1.place);
                $$.arr = false;
              }
              ;

  var: IDENT
              {
                const Symbol *symbol = lookup_symbol($1, @1.first_line);
                if(symbol != NULL && symbol->isArray) {
                  semantic_error(@1.first_line, "array variable \"" + std::string($1) + "\" requires an index");
                }
                $$.code = strdup("");
                $$.place = strdup($1);
                $$.index = strdup("");
                $$.arr = false;
              }
              | IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET
              {
                const Symbol *symbol = lookup_symbol($1, @1.first_line);
                if(symbol != NULL && !symbol->isArray) {
                  semantic_error(@1.first_line, "scalar variable \"" + std::string($1) + "\" cannot be indexed");
                }
                $$.code = strdup($3.code);
                $$.place = strdup($1);
                $$.index = strdup($3.place);
                $$.arr = true;
              }
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
    std::string name;
    do {
        name = "_t" + std::to_string(count++);
    } while(symbols.count(name) > 0 || generatedTemps.count(name) > 0);
    generatedTemps.insert(name);
    return name;
}

std::string new_label() {
    static int count = 0;
    return "label_" + std::to_string(count++);
}

std::string parameter_assignments(const char *declarationCode) {
    std::istringstream declarations(declarationCode);
    std::string line;
    std::string code;
    int position = 0;

    while(std::getline(declarations, line)) {
        if(line.compare(0, 2, ". ") == 0) {
            code += "= " + line.substr(2) + ", $" + std::to_string(position++) + "\n";
        }
    }

    return code;
}

void semantic_error(int line, const std::string &message) {
    semanticError = true;
    fprintf(stderr, "Error line %d: %s.\n", line, message.c_str());
}

void begin_function(const char *name, int line) {
    currentFunction = name;
    symbols.clear();
    generatedTemps.clear();

    if(funcs.count(name) > 0) {
        semantic_error(line, "function \"" + std::string(name) + "\" is multiply-defined");
    } else {
        funcs.insert(name);
    }

    if(strcmp(name, "main") == 0) {
        mainFunc = true;
    }
}

std::string declare_symbols(const char *names, bool isArray, int arraySize, int line) {
    std::istringstream input(names);
    std::string name;
    std::string code;

    while(std::getline(input, name)) {
        if(name.empty()) {
            continue;
        }

        if(reserved.count(name) > 0) {
            semantic_error(line, "symbol \"" + name + "\" uses a reserved keyword");
        } else if(name == currentFunction) {
            semantic_error(line, "symbol \"" + name + "\" has the same name as its function");
        } else if(symbols.count(name) > 0) {
            semantic_error(line, "symbol \"" + name + "\" is multiply-defined");
        } else {
            symbols[name] = {isArray, arraySize};
        }

        if(isArray) {
            code += ".[] " + name + ", " + std::to_string(arraySize) + "\n";
        } else {
            code += ". " + name + "\n";
        }
    }

    return code;
}

const Symbol *lookup_symbol(const char *name, int line) {
    std::map<std::string, Symbol>::const_iterator found = symbols.find(name);
    if(found == symbols.end()) {
        semantic_error(line, "used variable \"" + std::string(name) + "\" was not previously declared");
        return NULL;
    }
    return &found->second;
}

void validate_program() {
    if(!mainFunc) {
        semantic_error(1, "main function is not defined");
    }

    for(const FunctionCall &call : functionCalls) {
        if(funcs.count(call.name) == 0) {
            semantic_error(call.line, "called function \"" + call.name + "\" was not defined");
        }
    }
}
