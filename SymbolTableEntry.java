public class SymbolTableEntry {
    public enum Class { LOCAL_VAR, GLOBAL_VAR, FUNCTION, PRIM_TYPE }

    public final SymbolTableEntry TYPE;
    public final Class CLS;

    public SymbolTableEntry(SymbolTableEntry type, Class cls) {
        this.TYPE = type;
        this.CLS  = cls;
    }

    public String toString() {
        return String.format("%s {TYPE = %s, CLS = %s}", getClass().getName(), TYPE, CLS);
    }
}
