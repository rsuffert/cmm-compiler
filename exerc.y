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

ListaDecl : {currentClass = SymbolTableEntry.Class.GLOBAL_VAR;} DeclVar ListaDecl
          | DeclFun ListaDecl
          | // vazio
          ;

DeclVar : Tipo {currentType = (SymbolTableEntry)$1;} ListaIdent ';'

Tipo : INT      {$$ = TP_INT;}
     | DOUBLE   {$$ = TP_DOUBLE;}
     | BOOLEAN  {$$ = TP_BOOLEAN;}
     ;

ListaIdent : IDENT ',' ListaIdent           {addSymbolToTable($1, false);}
           | IDENT '[' E ']' ',' ListaIdent {addSymbolToTable($1, true);}
           | IDENT                          {addSymbolToTable($1, false);}
           | IDENT '[' E ']'                {addSymbolToTable($1, true);}
           ;

DeclFun : FUNC TipoOuVoid IDENT '(' FormalPar ')' '{' {currentClass = SymbolTableEntry.Class.LOCAL_VAR;} DeclVar ListaCmd '}' 

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
                        SymbolTableEntry symbolType = symbolTable.get(symbolId);
                        SymbolTableEntry exprType = (SymbolTableEntry)$3;
                        if (symbolType.getType() != exprType.getType())
                          semerror("cannot assign expression of type " + primTypeToStr(exprType) + " to variable '" + symbolId +
                                   "' of type " + primTypeToStr(symbolType));
                        if (symbolType.getType() == TP_ARRAY || exprType.getType() == TP_ARRAY)
                          if (symbolType.getArrayBaseType() != exprType.getArrayBaseType())
                            semerror("cannot assign expression of type " + primTypeToStr(exprType) + " to variable '" + symbolId +
                                     "' of type " + primTypeToStr(symbolType));
                        $$ = symbolType;
                      }
    | IDENT '[' E ']' '=' E ';' {
                                  String symbolId = $1;
                                  if (!symbolTable.contains(symbolId))
                                    semerror("symbol '" + symbolId + "' not declared");
                                  SymbolTableEntry symbolType = symbolTable.get(symbolId);
                                  if (symbolType.getType() != TP_ARRAY)
                                    semerror("symbol '" + symbolId + "' is not of array type");
                                  SymbolTableEntry arrayBaseType = symbolType.getArrayBaseType();
                                  SymbolTableEntry sizeType = (SymbolTableEntry)$3;
                                  if (sizeType.getType() != TP_INT)
                                    semerror("array size must be of type int");
                                  SymbolTableEntry exprType = (SymbolTableEntry)$6;
                                  if (arrayBaseType != exprType)
                                    semerror("cannot assign expression of type " + primTypeToStr(exprType) + " to variable '" + symbolId +
                                             "' of type " + primTypeToStr(symbolType));
                                  $$ = symbolType;
                                }
    | IF '(' E ')' Cmd RestoIf
    | RETURN E ';'
    ;

RestoIf : ELSE Cmd
        | // vazio
        ;

E : E '+' E {$$ = checkType('+', (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | E '-' E {$$ = checkType('-', (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | E '*' E {$$ = checkType('*', (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | E '/' E {$$ = checkType('/', (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | E '<' E {$$ = checkType('<', (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | E '>' E {$$ = checkType('>', (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | E LE E  {$$ = checkType((char)LE,  (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | E GE E  {$$ = checkType((char)GE,  (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | E EQ E  {$$ = checkType((char)EQ,  (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | E NEQ E {$$ = checkType((char)NEQ, (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | E AND E {$$ = checkType((char)AND, (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | E OR E  {$$ = checkType((char)OR,  (SymbolTableEntry)$1, (SymbolTableEntry)$3);}
  | '!' E   {$$ = checkType('!', (SymbolTableEntry)$2, null);    }
  | INT_LITERAL    {$$ = TP_INT;}
  | DOUBLE_LITERAL {$$ = TP_DOUBLE;}
  | TRUE           {$$ = TP_BOOLEAN;}
  | FALSE          {$$ = TP_BOOLEAN;}
  | IDENT '[' E ']' {
                      String symbolId = $1;
                      if (!symbolTable.contains(symbolId))
                        semerror("symbol '" + symbolId + "' not declared");
                      SymbolTableEntry symbolType = symbolTable.get(symbolId);
                      if (symbolType.getType() != TP_ARRAY)
                        semerror("symbol '" + symbolId + "' is not of array type (not indexable)");
                      SymbolTableEntry arrayBaseType = symbolType.getArrayBaseType();
                      SymbolTableEntry sizeType = (SymbolTableEntry)$3;
                      if (sizeType.getType() != TP_INT)
                        semerror("array size must be of type int");
                      $$ = symbolType;
                    }
  | IDENT   {
              String symbolId = $1;
              if (!symbolTable.contains(symbolId))
                semerror("symbol '" + symbolId + "' not declared");
              $$ = symbolTable.get(symbolId);                
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

  private SymbolTableEntry currentType;
  private SymbolTableEntry.Class currentClass;

  public static final SymbolTableEntry TP_INT = new SymbolTableEntry(null, SymbolTableEntry.Class.PRIM_TYPE);
  public static final SymbolTableEntry TP_DOUBLE = new SymbolTableEntry(null, SymbolTableEntry.Class.PRIM_TYPE);
  public static final SymbolTableEntry TP_BOOLEAN = new SymbolTableEntry(null, SymbolTableEntry.Class.PRIM_TYPE);
  public static final SymbolTableEntry TP_ARRAY = new SymbolTableEntry(null, SymbolTableEntry.Class.PRIM_TYPE);

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

  public boolean isNumeric(SymbolTableEntry type) {
    return type == TP_INT || type == TP_DOUBLE;
  }

  public String primTypeToStr(SymbolTableEntry type) {
    if (type.getType() == TP_INT)
      return "int";
    if (type.getType() == TP_DOUBLE)
      return "double";
    if (type.getType() == TP_BOOLEAN)
      return "boolean";
    if (type.getType() == TP_ARRAY)
      return primTypeToStr(type.getArrayBaseType()) + "[]";
    throw new IllegalArgumentException("Unknown type: " + type);
  }

  public String operatorToStr(char operator) {
    boolean isAscii = operator >= 0 && operator <= 127;
    if (isAscii)
      return String.valueOf((char) operator);
    switch (operator) {
      case LE:  return "<=";
      case GE:  return ">=";
      case EQ:  return "==";
      case NEQ: return "!=";
      case AND: return "&&";
      case OR:  return "||";
      default:
        throw new IllegalArgumentException("Unknown operator: " + operator);
    }
  }

  public void addSymbolToTable(String symbolId, boolean isArray) {
    SymbolTableEntry symbolType = new SymbolTableEntry(currentType, currentClass);
    if (isArray)
      symbolType = new SymbolTableEntry(currentType, TP_ARRAY, currentClass);
    try {
      symbolTable.add(symbolId, symbolType);
    } catch (IllegalArgumentException e) {
      semerror(e.getMessage());
    }
  }

  public SymbolTableEntry checkType(char operator, SymbolTableEntry leftType, SymbolTableEntry rightType) {
    switch(operator) {
      case '+':
      case '-':
      case '*':
      case '/':
        if (!isNumeric(leftType.getType()) || !isNumeric(rightType.getType()))
          semerror("cannot operate " + primTypeToStr(leftType) + " " + operatorToStr(operator) + " " + primTypeToStr(rightType));
        if (leftType.getType() == TP_DOUBLE || rightType.getType() == TP_DOUBLE)
          return TP_DOUBLE;
        return TP_INT;
      case '<':
      case '>':
      case LE:
      case GE:
        if (!isNumeric(leftType.getType()) || !isNumeric(rightType.getType()))
          semerror("cannot operate " + primTypeToStr(leftType) + " " + operatorToStr(operator) + " " + primTypeToStr(rightType));
        return TP_BOOLEAN;
      case AND:
      case OR:
        if (leftType.getType() != TP_BOOLEAN || rightType.getType() != TP_BOOLEAN)
          semerror("cannot operate " + primTypeToStr(leftType) + " " + operatorToStr(operator) + " " + primTypeToStr(rightType));
        return TP_BOOLEAN;
      case '!':
        if (leftType.getType() != TP_BOOLEAN)
          semerror("cannot operate " + operator + leftType.getType());
        return TP_BOOLEAN;
      case EQ:
      case NEQ:
        if (leftType.getType() != rightType.getType())
          semerror("cannot operate " + primTypeToStr(leftType) + " " + operatorToStr(operator) + " " + primTypeToStr(rightType));
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