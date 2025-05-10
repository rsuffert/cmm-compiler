%%

%byaccj


%{
  private Parser yyparser;

  public Yylex(java.io.Reader r, Parser yyparser) {
    this(r);
    this.yyparser = yyparser;
  }
%}

%integer
%line
%char

WHSPACE=[\n\r\ \t\b\012]

%%

"$TRACE_ON"  { yyparser.setDebug(true);  }
"$TRACE_OFF" { yyparser.setDebug(false); }


int { return Parser.INT; }
double { return Parser.DOUBLE; }
boolean { return Parser.BOOLEAN; }
void { return Parser.VOID; }
/* new { return Parser.NEW; } */

func { return Parser.FUNC; }
while { return Parser.WHILE; }
if { return Parser.IF; }
else { return Parser.ELSE; }
return { return Parser.RETURN; }




"||" { return Parser.OR; }
"&&" { return Parser.AND; }
"==" { return Parser.EQ; }
"!=" { return Parser.NEQ; }
"<=" { return Parser.LE; }
">=" { return Parser.GE; }
"["  { return Parser.LBRACK;}
"]"  { return Parser.RBRACK;}


[0-9]+(\.[0-9]+)? { return Parser.NUM;}
[a-zA-Z][a-zA-Z0-9]* { return Parser.IDENT;}

";" |
"(" |
")" |
"{" |
"}" |
"," |
"=" |
"+" |
"-" |
"*" |
"/" | 
">" |
"<" |
"!" { return yytext().charAt(0); } 

{WHSPACE}+ {}

. {
  System.err.println(String.format(
      "%sLEXICAL ERROR: invalid token '%s' at (%d,%d)%s",
      ConsoleColors.RED, yytext(), yyline, yychar, ConsoleColors.RESET
  ));
  return YYEOF;
}