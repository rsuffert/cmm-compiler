public class SymbolTableEntry {
    public enum Class { LOCAL_VAR, GLOBAL_VAR, FUNCTION, PRIM_TYPE }

    private SymbolTableEntry type;
    private Class cls;

    public SymbolTableEntry(SymbolTableEntry type, Class cls) {
        this.type = type;
        this.cls  = cls;
    }

    public SymbolTableEntry getType() {
        if (type == null) return this; // this is a base type, so return the object itself
        return type; // this is a wrapper, so return the underlying type
    }

    public Class getCls() {
        return cls;
    }

    public String toString() {
        return String.format("%s {TYPE = %s, CLS = %s}", getClass().getName(), type, cls);
    }
}
