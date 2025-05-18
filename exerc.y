%{
  import java.io.*;
%}

%token INT, DOUBLE, BOOLEAN, VOID, FUNC, WHILE, IF, ELSE, IDENT, INT_LITERAL, DOUBLE_LITERAL, RETURN, OR, AND, EQ, NEQ, LE, GE, TRUE, FALSE

%type <obj> Tipo
%type <obj> E
%type <obj> Cmd
%type <sval> IDENT

%right '='
%left OR
%left AND
%left EQ NEQ
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/'
%right '!'

%%

Prog : ListaDecl
     ;

ListaDecl : DeclVar ListaDecl
          | DeclFun ListaDecl
          | // vazio
          ;

DeclVar : Tipo {currentType = (Type)$1;} ListaIdent ';'

Tipo : INT      {$$ = TP_INT;}
     | DOUBLE   {$$ = TP_DOUBLE;}
     | BOOLEAN  {$$ = TP_BOOLEAN;}
     ;

ListaIdent : IDENT ',' ListaIdent {
                                    String symbolId = $1;
                                    try {
                                      symbolTable.add(symbolId, currentType);
                                    } catch (IllegalArgumentException e) {
                                      semerror(e.getMessage());
                                    }
                                  }
           | IDENT '[' E ']' ',' ListaIdent
           | IDENT  {
                      String symbolId = $1;
                      try {
                        symbolTable.add(symbolId, currentType);
                      } catch (IllegalArgumentException e) {
                        semerror(e.getMessage());
                      }
                    }
           | IDENT '[' E ']'
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
    | IDENT '=' E ';' {
                        String symbolId = $1;
                        if (!symbolTable.contains(symbolId))
                          semerror("symbol '" + symbolId + "' not declared");
                        Type symbolType = symbolTable.getType(symbolId);
                        Type exprType = (Type)$3;
                        if (symbolType != exprType)
                          semerror("cannot assign expression of type " + exprType + " to variable '" + symbolId + "' of type " + symbolType);
                        $$ = symbolType;
                      }
    | IDENT '[' E ']' '=' E ';'
    | IF '(' E ')' Cmd RestoIf
    | RETURN E ';'
    ;

RestoIf : ELSE Cmd
        | // vazio
        ;

E : E '+' E {$$ = checkType('+', (Type)$1, (Type)$3);}
  | E '-' E {$$ = checkType('-', (Type)$1, (Type)$3);}
  | E '*' E {$$ = checkType('*', (Type)$1, (Type)$3);}
  | E '/' E {$$ = checkType('/', (Type)$1, (Type)$3);}
  | E '<' E {$$ = checkType('<', (Type)$1, (Type)$3);}
  | E '>' E {$$ = checkType('>', (Type)$1, (Type)$3);}
  | E LE E  {$$ = checkType((char)LE,  (Type)$1, (Type)$3);}
  | E GE E  {$$ = checkType((char)GE,  (Type)$1, (Type)$3);}
  | E EQ E  {$$ = checkType((char)EQ,  (Type)$1, (Type)$3);}
  | E NEQ E {$$ = checkType((char)NEQ, (Type)$1, (Type)$3);}
  | E AND E {$$ = checkType((char)AND, (Type)$1, (Type)$3);}
  | E OR E  {$$ = checkType((char)OR,  (Type)$1, (Type)$3);}
  | '!' E   {$$ = checkType('!', (Type)$2, null);    }
  | INT_LITERAL    {$$ = TP_INT;}
  | DOUBLE_LITERAL {$$ = TP_DOUBLE;}
  | TRUE           {$$ = TP_BOOLEAN;}
  | FALSE          {$$ = TP_BOOLEAN;}
  | IDENT   {
              String symbolId = $1;
              if (!symbolTable.contains(symbolId))
                semerror("symbol '" + symbolId + "' not declared");
              $$ = symbolTable.getType(symbolId);                
            }
  | '(' E ')'
  | IDENT '(' ListaArgs ')' // chamada de funcao
  ;

ListaArgs : E ',' ListaArgs
          | E
          ;

%%

  private Yylex lexer;
  private SymbolTable symbolTable = new SymbolTable();

  private Type currentType;

  public static final Type TP_INT = new Type("int");
  public static final Type TP_DOUBLE = new Type("double");
  public static final Type TP_BOOLEAN = new Type("boolean");

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

  public void semerror(String error) {
    System.err.println(String.format(
        "%sSEMANTIC ERROR: %s%s",
        ConsoleColors.RED, error, ConsoleColors.RESET
    ));
    System.exit(1);
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

  public boolean isNumeric(Type type) {
    return type == TP_INT || type == TP_DOUBLE;
  }

  public Type checkType(char operator, Type leftType, Type rightType) {
    switch(operator) {
      case '+':
      case '-':
      case '*':
      case '/':
        if (!isNumeric(leftType) || !isNumeric(rightType))
          semerror("cannot operate " + leftType + " " + operator + " " + rightType);
        if (leftType == TP_DOUBLE || rightType == TP_DOUBLE)
          return TP_DOUBLE;
        return TP_INT;
      case '<':
      case '>':
      case LE:
      case GE:
        if (!isNumeric(leftType) || !isNumeric(rightType))
          semerror("cannot operate " + leftType + " " + operator + " " + rightType);
        return TP_BOOLEAN;
      case AND:
      case OR:
        if (leftType != TP_BOOLEAN || rightType != TP_BOOLEAN)
          semerror("cannot operate " + leftType + " " + operator + " " + rightType);
        return leftType;
      case '!':
        if (leftType != TP_BOOLEAN)
          semerror("cannot operate " + operator + leftType);
        return leftType;
      case EQ:
      case NEQ:
        if (leftType != rightType)
          semerror("cannot operate " + leftType + " " + operator + " " + rightType);
        return TP_BOOLEAN;
    }
    return null;
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