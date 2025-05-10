%{
  import java.io.*;
%}
   

%token INT, DOUBLE, BOOLEAN, VOID, FUNC, WHILE, IF, ELSE, IDENT, NUM, RETURN, OR, AND, EQ, NEQ, LE, GE, LBRACK, RBRACK //NEW

%right '='
%left OR
%left AND
%left EQ NEQ
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/'
%right '!'
%left LBRACK RBRACK

%%

Prog : ListaDecl
     ;

ListaDecl : DeclVar ListaDecl
          | DeclFun ListaDecl
          | // vazio
          ;

DeclVar : Tipo ListaIdent ';'
        ;

Tipo : INT
     | DOUBLE
     | BOOLEAN
     ;

ListaIdent : IDENT ',' ListaIdent
           | E
           | IDENT
           ;

DeclFun : FUNC TipoOuVoid IDENT '(' FormalPar ')' '{' DeclVar ListaCmd '}' 

TipoOuVoid : Tipo
           | VOID
           ;

FormalPar : ParamList
          | // vazio
          ;

ParamList : Tipo IDENT ',' ParamList
          | Tipo IDENT
          ;

Bloco : '{' ListaCmd '}'

ListaCmd : Cmd ListaCmd
         | // vazio
         ;

Cmd : Bloco
    | WHILE '(' E ')' Cmd
    | IDENT '=' E ';'
    | IDENT LBRACK E RBRACK '=' E ';'
    | IF '(' E ')' Cmd RestoIf
    | RETURN E ';'
    ;

RestoIf : ELSE Cmd
        | // vazio
        ;

E : E '+' E
  | E '-' E
  | E '*' E 
  | E '/' E
  | E '<' E
  | E '>' E
  | E LE E
  | E GE E
  | E EQ E
  | E NEQ E
  | E AND E
  | E OR E
  | '!' E
  | '(' E ')'
  | E LBRACK E RBRACK
  | NUM
  | IDENT
  ;


%%

  private Yylex lexer;


  private int yylex () {
    int yyl_return = -1;
    try {
      yylval = new ParserVal(0);
      yyl_return = lexer.yylex();
    }
    catch (IOException e) {
      System.err.println("IO error :"+e.getMessage());
    }
    return yyl_return;
  }


  public void yyerror (String error) {
    System.err.println(String.format(
        "%sSYNTAX ERROR: %s%s",
        ConsoleColors.RED, error, ConsoleColors.RESET
    ));
    System.exit(1);
  }


  public Parser(Reader r) {
    lexer = new Yylex(r, this);
  }


  static boolean interactive;

  public void setDebug(boolean debug) {
    yydebug = debug;
  }


  public static void main(String args[]) throws IOException {
    Parser yyparser;
    if ( args.length > 0 ) {
      // parse a file
      yyparser = new Parser(new FileReader(args[0]));
    }
    else {System.out.print("> ");
      interactive = true;
	    yyparser = new Parser(new InputStreamReader(System.in));
    }

    yyparser.yyparse();
    
  //  if (interactive) {
      System.out.println();
      System.out.println(String.format(
        "%sSuccess!%s",
        ConsoleColors.GREEN, ConsoleColors.RESET
      ));
  //  }
  }