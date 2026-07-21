/* CS152 MINI-L Phase 2 lexer */

%option noyywrap

%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "y.tab.h"

  int currLine = 1;
  int currPos = 1;

  static int token(int tokenType) {
    currPos += yyleng;
    return tokenType;
  }

  static void lexical_error(const char *kind) {
    fprintf(stderr, "Error at line %d, column %d: %s \"%s\"\n", currLine, currPos, kind, yytext);
    exit(1);
  }
%}

DIGIT [0-9]
LETTER [a-zA-Z]
IDENT {LETTER}({LETTER}|{DIGIT}|"_")*({LETTER}|{DIGIT})|{LETTER}

%%

[ \t\r]+               { currPos += yyleng; }
\n                     { currLine++; currPos = 1; }
"##".*                 { currPos += yyleng; }

"function"             { return token(FUNCTION); }
"beginparams"          { return token(BEGIN_PARAMS); }
"endparams"            { return token(END_PARAMS); }
"beginlocals"          { return token(BEGIN_LOCALS); }
"endlocals"            { return token(END_LOCALS); }
"beginbody"            { return token(BEGIN_BODY); }
"endbody"              { return token(END_BODY); }
"integer"              { return token(INTEGER); }
"array"                { return token(ARRAY); }
"enum"                 { return token(ENUM); }
"of"                   { return token(OF); }
"if"                   { return token(IF); }
"then"                 { return token(THEN); }
"endif"                { return token(ENDIF); }
"else"                 { return token(ELSE); }
"for"                  { return token(FOR); }
"while"                { return token(WHILE); }
"do"                   { return token(DO); }
"beginloop"            { return token(BEGINLOOP); }
"endloop"              { return token(ENDLOOP); }
"continue"             { return token(CONTINUE); }
"read"                 { return token(READ); }
"write"                { return token(WRITE); }
"and"                  { return token(AND); }
"or"                   { return token(OR); }
"not"                  { return token(NOT); }
"true"                 { return token(TRUE); }
"false"                { return token(FALSE); }
"return"               { return token(RETURN); }

"-"                    { return token(SUB); }
"+"                    { return token(ADD); }
"*"                    { return token(MULT); }
"/"                    { return token(DIV); }
"%"                    { return token(MOD); }

"=="                   { return token(EQ); }
"<>"                   { return token(NEQ); }
"<="                   { return token(LTE); }
">="                   { return token(GTE); }
"<"                    { return token(LT); }
">"                    { return token(GT); }

":="                   { return token(ASSIGN); }
";"                    { return token(SEMICOLON); }
":"                    { return token(COLON); }
","                    { return token(COMMA); }
"("                    { return token(L_PAREN); }
")"                    { return token(R_PAREN); }
"["                    { return token(L_SQUARE_BRACKET); }
"]"                    { return token(R_SQUARE_BRACKET); }

{DIGIT}+({LETTER}|"_")({LETTER}|{DIGIT}|"_")* {
  lexical_error("identifier must begin with a letter:");
}

"_"({LETTER}|{DIGIT}|"_")* {
  lexical_error("identifier must begin with a letter:");
}

{LETTER}({LETTER}|{DIGIT}|"_")*"_" {
  lexical_error("identifier cannot end with an underscore:");
}

{DIGIT}+ {
  yylval.numVal = atoi(yytext);
  return token(NUMBER);
}

{IDENT} {
  yylval.charVal = strdup(yytext);
  return token(IDENT);
}

. {
  lexical_error("unrecognized symbol:");
}

%%
