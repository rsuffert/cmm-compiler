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

ListaDecl : {currentClass = SymbolTable.Entry.Class.GLOBAL_VAR;} DeclVar ListaDecl
          | DeclFun ListaDecl
          | // vazio
          ;

DeclVar : Tipo {currentType = (SymbolTable.Entry)$1;} ListaIdent ';'

Tipo : INT      {$$ = TP_INT;}
     | DOUBLE   {$$ = TP_DOUBLE;}
     | BOOLEAN  {$$ = TP_BOOLEAN;}
     ;

ListaIdent : IDENT ',' ListaIdent           {addSymbolToTable($1, false);}
           | IDENT '[' E ']' ',' ListaIdent {addSymbolToTable($1, true);}
           | IDENT                          {addSymbolToTable($1, false);}
           | IDENT '[' E ']'                {addSymbolToTable($1, true);}
           ;

DeclFun : FUNC TipoOuVoid IDENT '(' FormalPar ')' '{' {currentClass = SymbolTable.Entry.Class.LOCAL_VAR;} DeclVar ListaCmd '}' 

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
    | IDENT '=' E ';'           {$$ = assign($1, (SymbolTable.Entry)$3, false, null);}
    | IDENT '[' E ']' '=' E ';' {$$ = assign($1, (SymbolTable.Entry)$6, true, (SymbolTable.Entry)$3);}
    | IF '(' E ')' Cmd RestoIf
    | RETURN E ';'
    ;

RestoIf : ELSE Cmd
        | // vazio
        ;

E : E '+' E {$$ = checkType('+',       (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | E '-' E {$$ = checkType('-',       (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | E '*' E {$$ = checkType('*',       (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | E '/' E {$$ = checkType('/',       (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | E '<' E {$$ = checkType('<',       (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | E '>' E {$$ = checkType('>',       (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | E LE E  {$$ = checkType((char)LE,  (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | E GE E  {$$ = checkType((char)GE,  (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | E EQ E  {$$ = checkType((char)EQ,  (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | E NEQ E {$$ = checkType((char)NEQ, (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | E AND E {$$ = checkType((char)AND, (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | E OR E  {$$ = checkType((char)OR,  (SymbolTable.Entry)$1, (SymbolTable.Entry)$3);}
  | '!' E   {$$ = checkType('!',       (SymbolTable.Entry)$2, null);}
  | INT_LITERAL     {$$ = TP_INT;}
  | DOUBLE_LITERAL  {$$ = TP_DOUBLE;}
  | TRUE            {$$ = TP_BOOLEAN;}
  | FALSE           {$$ = TP_BOOLEAN;}
  | IDENT '[' E ']' {$$ = access($1, true, (SymbolTable.Entry)$3);}
  | IDENT           {$$ = access($1, false, null);}
  | '(' E ')'
  | IDENT '(' ListaArgs ')' // chamada de funcao
  ;

ListaArgs : E ',' ListaArgs
          | E
          ;

%%

  private Yylex lexer;
  private SymbolTable symbolTable = new SymbolTable();

  private SymbolTable.Entry currentType;
  private SymbolTable.Entry.Class currentClass;

  public static final SymbolTable.Entry TP_INT = new SymbolTable.Entry(null, SymbolTable.Entry.Class.PRIM_TYPE);
  public static final SymbolTable.Entry TP_DOUBLE = new SymbolTable.Entry(null, SymbolTable.Entry.Class.PRIM_TYPE);
  public static final SymbolTable.Entry TP_BOOLEAN = new SymbolTable.Entry(null, SymbolTable.Entry.Class.PRIM_TYPE);
  public static final SymbolTable.Entry TP_ARRAY = new SymbolTable.Entry(null, SymbolTable.Entry.Class.PRIM_TYPE);

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

  public boolean isNumeric(SymbolTable.Entry type) {
    return type == TP_INT || type == TP_DOUBLE;
  }

  public String primTypeToStr(SymbolTable.Entry type) {
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
    SymbolTable.Entry symbolType = new SymbolTable.Entry(currentType, currentClass);
    if (isArray)
      symbolType = new SymbolTable.Entry(currentType, TP_ARRAY, currentClass);
    try {
      symbolTable.add(symbolId, symbolType);
    } catch (IllegalArgumentException e) {
      semerror(e.getMessage());
    }
  }

  public SymbolTable.Entry assign(String symbolId, SymbolTable.Entry exprType, boolean isArray, SymbolTable.Entry arraySizeType) {
    if (!symbolTable.contains(symbolId))
        semerror("symbol '" + symbolId + "' not declared");

    SymbolTable.Entry symbolType = symbolTable.get(symbolId);
    if (isArray) {
      if (symbolType.getType() != TP_ARRAY)
        semerror("expected symbol '" + symbolId + "' to be of array type");
      if (arraySizeType.getType() != TP_INT)
        semerror("array size must be of type int");
      symbolType = symbolType.getArrayBaseType();
    }

    if (symbolType.getType() == TP_DOUBLE && exprType.getType() == TP_INT) // allow type coercion in assignment
      return symbolType;

    if (symbolType.getType() != exprType.getType())
      semerror("cannot assign expression of type " + primTypeToStr(exprType) + " to variable '" + symbolId +
                "' of type " + primTypeToStr(symbolType));

    return symbolType;
  }

  public SymbolTable.Entry access(String symbolId, boolean isArray, SymbolTable.Entry arrayIdxType) {
    if (!symbolTable.contains(symbolId))
      semerror("symbol '" + symbolId + "' not declared");

    SymbolTable.Entry symbolType = symbolTable.get(symbolId);

    if (!isArray) return symbolType;

    if (symbolType.getType() != TP_ARRAY)
      semerror("expected symbol '" + symbolId + "' to be of array type");
    if (arrayIdxType.getType() != TP_INT)
      semerror("array index must be of type int");
    return symbolType.getArrayBaseType();
  }

  public SymbolTable.Entry checkType(char operator, SymbolTable.Entry leftType, SymbolTable.Entry rightType) {
    switch(operator) {
      case '+':
      case '-':
      case '*':
      case '/':
        if (!isNumeric(leftType.getType()) || !isNumeric(rightType.getType()))
          semerror("cannot operate " + primTypeToStr(leftType) + " " + operatorToStr(operator) + " " + primTypeToStr(rightType));
        if (leftType.getType() == TP_DOUBLE || rightType.getType() == TP_DOUBLE) // type coercion
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
        if (isNumeric(leftType.getType()) && isNumeric(rightType.getType()))
          // we allow operating between int and double interchangeably for equality comparison
          return TP_BOOLEAN;
        if (leftType.getType() != rightType.getType())
          semerror("cannot operate " + primTypeToStr(leftType) + " " + operatorToStr(operator) + " " + primTypeToStr(rightType));
        return TP_BOOLEAN;
      default:
        throw new IllegalArgumentException("Unknown operator: " + operator);
    }
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