import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.LinkedList;

public class SymbolTable {
    private final Map<String, Entry> symbols;

    public SymbolTable() {
        symbols = new HashMap<>();
    }

    public void add(String name, Entry entry) {
        if (contains(name)) {
            throw new IllegalArgumentException("Symbol '" + name + "' already exists in the symbol table.");
        }
        symbols.put(name, entry);
    }

    public Entry get(String name) {
        if (!contains(name)) {
            throw new IllegalArgumentException("Symbol '" + name + "' does not exist in the symbol table.");
        }
        return symbols.get(name);
    }

    public boolean contains(String name) {
        return symbols.containsKey(name);
    }

    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("SymbolTable{\n");
        for (Map.Entry<String, Entry> entry : symbols.entrySet()) {
            sb.append("  ").append(entry.getKey()).append(": ").append(entry.getValue()).append("\n");
        }
        sb.append("}");
        return sb.toString();
    }

    public static class Entry {
        public enum Class { LOCAL_VAR, GLOBAL_VAR, PARAM_VAR, FUNCTION, PRIM_TYPE }
    
        // ========================== MEMBERS FOR PRIMITIVE SYMBOLS ==========================
        private Entry type;
        private Class cls;
    
        public Entry(Entry type, Class cls) {
            this.type = type;
            this.cls  = cls;
        }
    
        public Entry getType() {
            if (type == null) return this; // this is a base type, so return the object itself
            return type; // this is a wrapper, so return the underlying type
        }
    
        public Class getCls() {
            return cls;
        }
    
        // ========================== MEMBERS FOR ARRAY SYMBOLS ==========================
        private Entry arrayBaseType;
    
        public Entry(Entry arrayBaseType, Entry type, Class cls) {
            this(type, cls);
            this.arrayBaseType = arrayBaseType;
        }
    
        public Entry getArrayBaseType() {
            return arrayBaseType;
        }
    
        // ========================== MEMBERS FOR FUNCTION SYMBOLS ==========================
        private SymbolTable funcSymbolTable = new SymbolTable();
        private List<String> funcParamNames = new LinkedList<>();

        public SymbolTable getInternalSymbolTable() {
            return funcSymbolTable;
        }

        public String getFuncParamName(int idx) {
            return funcParamNames.get(idx);
        }

        public void appendFuncParamName(String name) {
            funcParamNames.add(name);
        }

        public int getFuncParamsCount() {
            return funcParamNames.size();
        }

        // ========================== MEMBERS FOR THE CLASS ==========================
        public String toString() {
            return String.format("%s {TYPE = %s, CLS = %s}", getClass().getName(), type, cls);
        }
    }    
}