%{
  import java.io.*;
%}

%token INT, DOUBLE, BOOLEAN, VOID, FUNC, WHILE, IF, ELSE, IDENT, INT_LITERAL, DOUBLE_LITERAL, RETURN, OR, AND, EQ, NEQ, LE, GE, TRUE, FALSE

%type <obj> Tipo
%type <obj> E
%type <obj> Cmd
%type <sval> IDENT
%type <obj> TipoOuVoid
%type <obj> FuncCall

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
        ;

Tipo : INT      {$$ = TP_INT;}
     | DOUBLE   {$$ = TP_DOUBLE;}
     | BOOLEAN  {$$ = TP_BOOLEAN;}
     ;

ListaIdent : IDENT ',' ListaIdent           {addSymbolToTable($1, currentType, currentScope, currentClass, false);}
           | IDENT '[' E ']' ',' ListaIdent {addSymbolToTable($1, currentType, currentScope, currentClass, true);}
           | IDENT                          {addSymbolToTable($1, currentType, currentScope, currentClass, false);}
           | IDENT '[' E ']'                {addSymbolToTable($1, currentType, currentScope, currentClass, true);}
           ;

DeclFun : FUNC TipoOuVoid IDENT {
                                  currentClass = SymbolTable.Entry.Class.FUNCTION;
                                  currentType = (SymbolTable.Entry)$2;
                                  addSymbolToTable($3, currentType, currentScope, currentClass, false);
                                  currentScope = symbolTable.get($3);
                                }
          '(' FormalPar ')' '{'
            {currentClass = SymbolTable.Entry.Class.LOCAL_VAR;}
            DeclVar
            ListaCmd 
          '}' 
          {currentScope = null;}
        ;

TipoOuVoid : Tipo
           | VOID {$$ = TP_VOID;}
           ;

FormalPar : ParamList
          | // vazio
          ;

ParamList : Tipo IDENT {
                          currentType = (SymbolTable.Entry)$1;
                          currentClass = SymbolTable.Entry.Class.PARAM_VAR;
                          currentScope.appendFuncParamName($2);
                          addSymbolToTable($2, currentType, currentScope, currentClass, false);
                       } ',' ParamList 
          | Tipo IDENT {
                          currentType = (SymbolTable.Entry)$1;
                          currentClass = SymbolTable.Entry.Class.PARAM_VAR;
                          currentScope.appendFuncParamName($2);
                          addSymbolToTable($2, currentType, currentScope, currentClass, false);
                       }
          | Tipo IDENT '[' ']' {
                          currentType = (SymbolTable.Entry)$1;
                          currentClass = SymbolTable.Entry.Class.PARAM_VAR;
                          currentScope.appendFuncParamName($2);
                          addSymbolToTable($2, currentType, currentScope, currentClass, true);
                       } ',' ParamList
          | Tipo IDENT '[' ']' {
                          currentType = (SymbolTable.Entry)$1;
                          currentClass = SymbolTable.Entry.Class.PARAM_VAR;
                          currentScope.appendFuncParamName($2);
                          addSymbolToTable($2, currentType, currentScope, currentClass, true);
                       } 
          ;

Bloco : '{' ListaCmd '}'
      ;

ListaCmd : Cmd ListaCmd
         | // vazio
         ;

Cmd : Bloco
    | WHILE '(' E ')' Cmd       {if (((SymbolTable.Entry)$3).getType() != TP_BOOLEAN) semerror("while condition must be of type boolean");}
    | IDENT '=' E ';'           {$$ = assign($1, (SymbolTable.Entry)$3, currentScope, false, null);}
    | IDENT '[' E ']' '=' E ';' {$$ = assign($1, (SymbolTable.Entry)$6, currentScope, true, (SymbolTable.Entry)$3);}
    | IF '(' E ')' Cmd RestoIf  {if (((SymbolTable.Entry)$3).getType() != TP_BOOLEAN) semerror("if condition must be of type boolean");}
    | RETURN E ';'              {checkReturnType(currentScope, (SymbolTable.Entry)$2);}
    | RETURN ';'                {checkReturnType(currentScope, TP_VOID);}
    | FuncCall ';'
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
  | IDENT '[' E ']' {$$ = access($1, currentScope, true, (SymbolTable.Entry)$3);}
  | IDENT           {$$ = access($1, currentScope, false, null);}
  | '(' E ')'       {$$ = (SymbolTable.Entry)$2;} // parenthesis for grouping
  | FuncCall
  ;

FuncCall : IDENT  {
             SymbolTable.Entry funcActvCall = symbolTable.get($1);

             if (funcActvCall == null) { 
               semerror("symbol '" + $1 + "' not declared");
             }
             if (funcActvCall.getCls() != SymbolTable.Entry.Class.FUNCTION) {
               semerror("symbol '" + $1 + "' is not callable");
             }
             
             currentFuncCall = funcActvCall;

             funcContxStk.push(funcActvCall); 
             paramIdxStk.push(0);                    
           }
           '(' ListaArgs ')'
           { 
             SymbolTable.Entry funcActvStck = funcContxStk.peek();
             int currParamStck = paramIdxStk.peek();

             if (currParamStck != funcActvStck.getFuncParamsCount()){
               semerror("function '" + $1 + "' expected " + funcActvStck.getFuncParamsCount() + " parameters, but got " + currParamStck);
             }
             $$ = funcActvStck.getType();
             funcContxStk.pop();
             paramIdxStk.pop();
           }
         ;

ListaArgs : E {
              if (funcContxStk.isEmpty()){ 
                  semerror("SEMANTIC INTERNAL ERROR: Function context stack is empty during argument parsing.");
              } else {
                  SymbolTable.Entry actvFuncCall = funcContxStk.peek(); 
                  int currArgIdx = paramIdxStk.pop();
                  
                  checkFuncParam(actvFuncCall, currArgIdx, (SymbolTable.Entry)$1);
                  paramIdxStk.push(currArgIdx + 1);
                 
              }
            } ',' ListaArgs
          | E {
              
              if (funcContxStk.isEmpty()){
                  semerror("SEMANTIC INTERNAL ERROR: Function context stack is empty during argument parsing.");
              } else {
                  SymbolTable.Entry actvFuncCall = funcContxStk.peek(); 
                  int currArgIdx = paramIdxStk.pop();
                 
                  checkFuncParam(actvFuncCall, currArgIdx, (SymbolTable.Entry)$1);
                  paramIdxStk.push(currArgIdx + 1);
                  
              }
            }
          | // vazio
          ;

%%

  private Yylex lexer;
  private SymbolTable symbolTable = new SymbolTable();

  private SymbolTable.Entry currentType;
  private SymbolTable.Entry.Class currentClass;
  private SymbolTable.Entry currentScope;
  private SymbolTable.Entry currentFuncCall;
  private int currentParamIdx;
  private java.util.Stack<SymbolTable.Entry> funcContxStk = new java.util.Stack<>();
  private java.util.Stack<Integer> paramIdxStk = new java.util.Stack<>();

  public static final SymbolTable.Entry TP_INT = new SymbolTable.Entry(null, SymbolTable.Entry.Class.PRIM_TYPE);
  public static final SymbolTable.Entry TP_DOUBLE = new SymbolTable.Entry(null, SymbolTable.Entry.Class.PRIM_TYPE);
  public static final SymbolTable.Entry TP_BOOLEAN = new SymbolTable.Entry(null, SymbolTable.Entry.Class.PRIM_TYPE);
  public static final SymbolTable.Entry TP_VOID = new SymbolTable.Entry(null, SymbolTable.Entry.Class.PRIM_TYPE);
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
    if (type.getType() == TP_VOID)
      return "void";
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

  public void addSymbolToTable(
      String symbolId, SymbolTable.Entry symbolType,
      SymbolTable.Entry scope, SymbolTable.Entry.Class cls,
      boolean isArray) {
    SymbolTable.Entry _symbolType = symbolType;
    if (isArray)
      _symbolType = new SymbolTable.Entry(symbolType, TP_ARRAY, cls);
    else if (cls == SymbolTable.Entry.Class.FUNCTION)
      _symbolType = new SymbolTable.Entry(symbolType, cls);

    SymbolTable _symbolTable = symbolTable;
    if (scope != null)
      _symbolTable = scope.getInternalSymbolTable();

    if (_symbolTable.contains(symbolId))
      semerror("symbol '" + symbolId + "' already declared in this scope");

    _symbolTable.add(symbolId, _symbolType);
  }

  public void checkReturnType(SymbolTable.Entry scope, SymbolTable.Entry exprType) {
    SymbolTable.Entry returnType = scope.getType();
    if (returnType.getType() == TP_VOID && exprType.getType() == TP_VOID) // allow empty return for void functions
      return;
    if (returnType.getType() == TP_DOUBLE && exprType.getType() == TP_INT) // allow type coercion
      return;
    if (returnType.getType() != exprType.getType())
      semerror("function of type " + primTypeToStr(returnType) + " attempted to return a value of type " + primTypeToStr(exprType));
  }

  public void checkFuncParam(SymbolTable.Entry funcEntry, int paramIdx, SymbolTable.Entry exprType) {
    if (paramIdx >= funcEntry.getFuncParamsCount())
      semerror("cannot analyze parameter " + (paramIdx+1) + " for a function that expects " + funcEntry.getFuncParamsCount() + " parameters");
    String paramName = funcEntry.getFuncParamName(paramIdx);
    SymbolTable.Entry paramType = funcEntry.getInternalSymbolTable().get(paramName);
    if (paramType.getType() == TP_DOUBLE && exprType.getType() == TP_INT) // allow type coercion
      exprType = TP_DOUBLE;
    if (paramType.getType() != exprType.getType())
      semerror("function expected parameter " + paramIdx + " to be of type " + 
                primTypeToStr(paramType) + ", but got " + primTypeToStr(exprType));
    if (paramType.getType() == TP_ARRAY) {
      // due to the previous check, both types are arrays at this point
      if (paramType.getArrayBaseType().getType() != exprType.getArrayBaseType().getType())
        semerror("function expected array parameter " + paramIdx + " to be of type " + 
                  primTypeToStr(paramType) + ", but got " + primTypeToStr(exprType));
    }
  }

  public SymbolTable.Entry assign(String symbolId, SymbolTable.Entry exprType, SymbolTable.Entry scope, boolean isArray, SymbolTable.Entry arraySizeType) {
    SymbolTable.Entry symbolType = null;
    if (scope != null && scope.getInternalSymbolTable().contains(symbolId))
      symbolType = scope.getInternalSymbolTable().get(symbolId);
    else if (symbolTable.contains(symbolId))
      symbolType = symbolTable.get(symbolId);
    else
        semerror("symbol '" + symbolId + "' not declared");

    if (symbolType.getCls() == SymbolTable.Entry.Class.FUNCTION)
      semerror("cannot assign to symbol '" + symbolId + "' because it's a function");

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

  public SymbolTable.Entry access(String symbolId, SymbolTable.Entry scope, boolean isArray, SymbolTable.Entry arrayIdxType) {
    SymbolTable.Entry symbolType = null;
    if (scope != null && scope.getInternalSymbolTable().contains(symbolId))
      symbolType = scope.getInternalSymbolTable().get(symbolId);
    else if (symbolTable.contains(symbolId))
      symbolType = symbolTable.get(symbolId);
    else
        semerror("symbol '" + symbolId + "' not declared");

    if (symbolType.getCls() == SymbolTable.Entry.Class.FUNCTION)
      semerror("cannot access symbol '" + symbolId + "' because it's a function (should be called instead)");

    if (!isArray)
    // ensure array types are not unwrapped
      return symbolType.getType() == TP_ARRAY ? symbolType : symbolType.getType();

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
